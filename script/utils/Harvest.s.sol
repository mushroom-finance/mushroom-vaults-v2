// SPDX-License-Identifier: MIT
pragma solidity =0.8.23;

import { Script } from "forge-std/src/Script.sol";
import { console2 } from "forge-std/src/console2.sol";
import { VyperDeployer } from "Foundry-Vyper/VyperDeployer.sol";
import { DecimalStrings } from "src/libraries/DecimalStrings.sol";
import { IRegistry } from "src/interfaces/IRegistry.sol";
import { IVault, StrategyParams } from "src/interfaces/IVault.sol";
import { BaseStrategy } from "src/BaseStrategy.sol";
import { Strategy } from "src/strategies/lido/Strategy.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract Harvest is Script {
    using DecimalStrings for uint256;

    function run() public {
        uint256 broadcaster = vm.envUint("BROADCASTER");

        console2.log("broadcaster:", vm.addr(broadcaster));

        address vault = vm.envAddress("VAULT");
        address token = vm.envAddress("WETH");
        uint8 decimals = IERC20Metadata(token).decimals();
        address payable strategy = payable(vm.envAddress("STRATEGY"));

        vm.label(strategy, "Strategy");

        vm.startBroadcast(broadcaster);

        uint256 vaultBalance = IERC20Metadata(token).balanceOf(vault);
        console2.log("Balance of vault before harvest:", vaultBalance.decimalString(decimals, false));

        uint256 strategyBalance = IERC20Metadata(token).balanceOf(strategy);
        console2.log("Balance of strategy before harvest:", strategyBalance.decimalString(decimals, false));

        StrategyParams memory strategyInfo = IVault(vault).strategies(strategy);
        console2.log("StrategyParams before harvest:");
        console2.log(" - debtRatio:", strategyInfo.debtRatio.decimalString(4, true));
        console2.log(" - totalDebt:", strategyInfo.totalDebt.decimalString(decimals, false));
        console2.log(" - totalGain:", strategyInfo.totalGain.decimalString(decimals, false));
        console2.log(" - totalLoss:", strategyInfo.totalLoss.decimalString(decimals, false));

        console2.log("Strategy before harvest:");
        console2.log(" - wantBalance:", Strategy(strategy).wantBalance().decimalString(decimals, false));
        console2.log(" - wantBalance:", Strategy(strategy).stethBalance().decimalString(decimals, false));
        console2.log(
            " - estimatedTotalAssets:", BaseStrategy(strategy).estimatedTotalAssets().decimalString(decimals, false)
        );

        //        bool harvestTrigger = Strategy(strategy).harvestTrigger(1e9);
        //        console2.log("harvestTrigger:", harvestTrigger);

        //        Strategy(strategy).harvest();

        //        vaultBalance = IERC20Metadata(token).balanceOf(vault);
        //        console2.log("Balance of vault after harvest:", vaultBalance);

        //        strategyBalance = IERC20Metadata(token).balanceOf(strategy);
        //        console2.log("Balance of strategy after harvest:", strategyBalance);

        vm.stopBroadcast();
    }
}
