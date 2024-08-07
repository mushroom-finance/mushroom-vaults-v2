// SPDX-License-Identifier: MIT
pragma solidity =0.8.23;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IWETH } from "src/interfaces/IWETH.sol";
import { ILido } from "src/interfaces/ILido.sol";
import { IStableSwapSTETH } from "src/interfaces/curve/IStableSwapSTETH.sol";
import { BaseStrategy } from "src/BaseStrategy.sol";

contract Strategy is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;

    event UpdateReferral(address referral);
    event UpdateMaxSingleTrade(uint256 maxSingleTrade);
    event UpdatePeg(uint256 peg);
    event UpdateReportLoss(bool reportLoss);
    event UpdateDontInvest(bool dontInvest);
    event UpdateSlippageProtectionOut(uint256 slippageProtectionOut);

    IWETH public constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    ILido public constant STETH = ILido(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    IStableSwapSTETH public constant StableSwapSTETH = IStableSwapSTETH(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022);

    address private referral;
    uint256 public maxSingleTrade;
    uint256 public constant DENOMINATOR = 10_000;
    uint256 public slippageProtectionOut; // = 50; //out of 10000. 50 = 0.5%

    bool public reportLoss;
    bool public dontInvest;

    uint256 public peg = 100; // 100 = 1%

    int128 private constant WETH_ID = 0;
    int128 private constant STETH_ID = 1;

    constructor(address _vault) BaseStrategy(_vault) {
        // You can set these parameters on deployment to whatever you want
        maxReportDelay = 43_200;
        healthCheck = 0xDDCea799fF1699e98EDF118e0629A974Df7DF012; //hardcode healthcheck

        STETH.approve(address(StableSwapSTETH), type(uint256).max);

        maxSingleTrade = 1000 * 1e18;
        slippageProtectionOut = 500;
    }

    //we get eth
    receive() external payable { }

    function updateReferral(address _referral) external onlyEmergencyAuthorized {
        referral = _referral;
        emit UpdateReferral(referral);
    }

    function updateMaxSingleTrade(uint256 _maxSingleTrade) external onlyVaultManagers {
        maxSingleTrade = _maxSingleTrade;
        emit UpdateMaxSingleTrade(maxSingleTrade);
    }

    function updatePeg(uint256 _peg) external onlyVaultManagers {
        require(_peg <= 1000); //limit peg to max 10%
        peg = _peg;
        emit UpdatePeg(peg);
    }

    function updateReportLoss(bool _reportLoss) external onlyVaultManagers {
        reportLoss = _reportLoss;
        emit UpdateReportLoss(reportLoss);
    }

    function updateDontInvest(bool _dontInvest) external onlyVaultManagers {
        dontInvest = _dontInvest;
        emit UpdateDontInvest(dontInvest);
    }

    function updateSlippageProtectionOut(uint256 _slippageProtectionOut) external onlyVaultManagers {
        require(_slippageProtectionOut <= 10_000);
        slippageProtectionOut = _slippageProtectionOut;
        emit UpdateSlippageProtectionOut(slippageProtectionOut);
    }

    function invest(uint256 _amount) external onlyEmergencyAuthorized {
        _invest(_amount);
    }

    // should never have stuck eth but just in case
    function rescueStuckEth() external onlyEmergencyAuthorized {
        WETH.deposit{ value: address(this).balance }();
    }

    function name() external pure override returns (string memory) {
        // Add your own name here, suggestion e.g. "StrategyCreamMFI"
        return "StrategyLidoMFI";
    }

    // We hard code a peg here. This is so that we can build up a reserve of profit to cover peg volatility if we are
    // forced to deleverage
    // This may sound scary but it is the equivalent of using virtual price in a curve lp. As we have seen from many
    // exploits, virtual pricing is safer than touch pricing.
    function estimatedTotalAssets() public view override returns (uint256) {
        return stethBalance() * (DENOMINATOR - peg) / DENOMINATOR + wantBalance();
    }

    function estimatedPotentialTotalAssets() public view returns (uint256) {
        return stethBalance() + wantBalance();
    }

    function wantBalance() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    function stethBalance() public view returns (uint256) {
        return STETH.balanceOf(address(this));
    }

    function prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (uint256 _profit, uint256 _loss, uint256 _debtPayment)
    {
        uint256 wantBal = wantBalance();
        uint256 totalAssets = estimatedTotalAssets();

        uint256 debt = vault.strategies(address(this)).totalDebt;

        if (totalAssets >= debt) {
            _profit = totalAssets - debt;

            uint256 toWithdraw = _profit + _debtOutstanding;

            if (toWithdraw > wantBal) {
                uint256 willWithdraw = Math.min(maxSingleTrade, toWithdraw - wantBal);
                uint256 withdrawn = _divest(willWithdraw); //we step our withdrawals. adjust max single trade to
                    // withdraw more
                if (withdrawn < willWithdraw) {
                    _loss = willWithdraw - withdrawn;
                }
            }
            wantBal = wantBalance();

            //net off profit and loss
            if (_profit >= _loss) {
                _profit = _profit - _loss;
                _loss = 0;
            } else {
                _profit = 0;
                _loss = _loss - _profit;
            }

            //profit + _debtOutstanding must be <= wantBal. Prioritise profit first
            if (wantBal < _profit) {
                _profit = wantBal;
            } else if (wantBal < toWithdraw) {
                _debtPayment = wantBal - _profit;
            } else {
                _debtPayment = _debtOutstanding;
            }
        } else {
            if (reportLoss) {
                _loss = debt - totalAssets;
            }
        }
    }

    function ethToWant(uint256 _amtInWei) public pure override returns (uint256) {
        return _amtInWei;
    }

    function liquidateAllPositions() internal override returns (uint256 _amountFreed) {
        _divest(stethBalance());
        _amountFreed = wantBalance();
    }

    function adjustPosition(uint256 /* _debtOutstanding */ ) internal override {
        if (dontInvest) {
            return;
        }
        _invest(wantBalance());
    }

    function _invest(uint256 _amount) internal returns (uint256) {
        if (_amount == 0) {
            return 0;
        }

        _amount = Math.min(maxSingleTrade, _amount);
        uint256 before = stethBalance();

        WETH.withdraw(_amount);

        //test if we should buy instead of mint
        uint256 out = StableSwapSTETH.get_dy(WETH_ID, STETH_ID, _amount);
        if (out < _amount) {
            STETH.submit{ value: _amount }(referral);
        } else {
            StableSwapSTETH.exchange{ value: _amount }(WETH_ID, STETH_ID, _amount, _amount);
        }

        return stethBalance() - before;
    }

    function _divest(uint256 _amount) internal returns (uint256) {
        uint256 before = wantBalance();

        uint256 slippageAllowance = _amount * (DENOMINATOR - slippageProtectionOut) / DENOMINATOR;
        StableSwapSTETH.exchange(STETH_ID, WETH_ID, _amount, slippageAllowance);

        WETH.deposit{ value: address(this).balance }();

        return wantBalance() - before;
    }

    // we attempt to withdraw the full amount and let the user decide if they take the loss or not
    function liquidatePosition(uint256 _amountNeeded)
        internal
        override
        returns (uint256 _liquidatedAmount, uint256 _loss)
    {
        uint256 wantBal = wantBalance();
        if (wantBal < _amountNeeded) {
            uint256 toWithdraw = _amountNeeded - wantBal;
            uint256 withdrawn = _divest(toWithdraw);
            if (withdrawn < toWithdraw) {
                _loss = toWithdraw - withdrawn;
            }
        }

        _liquidatedAmount = _amountNeeded - _loss;
    }

    // NOTE: Can override `tendTrigger` and `harvestTrigger` if necessary

    function prepareMigration(address _newStrategy) internal override {
        uint256 stethBal = stethBalance();
        if (stethBal > 0) {
            SafeERC20.safeTransfer(STETH, _newStrategy, stethBal);
        }
    }

    // Override this to add all tokens/tokenized positions this contract manages
    // on a *persistent* basis (e.g. not just for swapping back to want ephemerally)
    // NOTE: Do *not* include `want`, already included in `sweep` below
    //
    // Example:
    //
    //    function protectedTokens() internal override view returns (address[] memory) {
    //      address[] memory protected = new address[](3);
    //      protected[0] = tokenA;
    //      protected[1] = tokenB;
    //      protected[2] = tokenC;
    //      return protected;
    //    }
    function protectedTokens() internal view override returns (address[] memory) { }
}
