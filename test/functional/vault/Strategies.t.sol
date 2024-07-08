// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { console2 } from "forge-std/src/console2.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { IWETH } from "src/interfaces/IWETH.sol";
import { IRegistry } from "src/interfaces/IRegistry.sol";
import { IVault, StrategyParams } from "src/interfaces/IVault.sol";
import { BaseStrategy, BaseStrategyInitializable } from "src/BaseStrategy.sol";
import { TestStrategy } from "src/strategies/test/TestStrategy.sol";

import { Fixture } from "test/shared/Fixture.sol";

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract StrategiesTest is Fixture {
    /// @dev A function invoked before each test case is run.
    function setUp() public override {
        // Instantiate the contract-under-test.
        super.setUp();

        vm.deal(governance, 100 ether);

        vm.prank(governance);
        IWETH(weth9).deposit{ value: 10 ether }();
    }

    /// @dev Basic test. Run it with `forge test -vvv` to see the console log.
    function test_liquidation_after_hack() external {
        // Deposit into vault
        vm.prank(governance);
        IERC20Metadata(weth9).approve(vault, type(uint256).max);
        vm.prank(governance);
        IVault(vault).deposit(1000);

        //  Deploy strategy and seed it with debt
        vm.prank(governance);
        IVault(vault).addStrategy(strategy, 2000, 0, 10 ** 21, 1000);
        vm.prank(governance);
        BaseStrategy(strategy).harvest();

        // The strategy suffers a loss
        uint256 stolenFunds = IERC20Metadata(weth9).balanceOf(strategy) / 2;
        vm.prank(governance);
        TestStrategy(strategy)._takeFunds(stolenFunds);
        uint256 strategyTotalAssetsAfterHack = IERC20Metadata(weth9).balanceOf(strategy);

        // Make sure strategy debt exceeds strategy assets
        StrategyParams memory params = IVault(vault).strategies(strategy);
        uint256 totalDebt = params.totalDebt;
        uint256 totalAssets = IERC20Metadata(weth9).balanceOf(strategy);
        assertGt(totalDebt, totalAssets);

        // Make sure the withdrawal results in liquidation
        uint256 amountToWithdraw = 100; // amountNeeded in BaseStrategy
        assertLe(amountToWithdraw, strategyTotalAssetsAfterHack);
        uint256 loss = totalDebt - totalAssets;
        assertLe(loss, amountToWithdraw);

        // Liquidate strategy
        vm.prank(vault);
        BaseStrategy(strategy).withdraw(amountToWithdraw);
    }

    /// @dev Fuzz test that provides random values for an unsigned integer, but which rejects zero as an input.
    /// If you need more sophisticated input validation, you should use the `bound` utility instead.
    /// See https://twitter.com/PaulRBerg/status/1622558791685242880

    /// @dev Fork test that runs against an Ethereum Mainnet fork. For this to work, you need to set `API_KEY_ALCHEMY`
    /// in your environment You can get an API key for free at https://alchemy.com.
}
