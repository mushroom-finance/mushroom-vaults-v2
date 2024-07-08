// SPDX-License-Identifier: MIT
pragma solidity =0.8.23;

import { Script, console2 } from "forge-std/src/Script.sol";

import { MAXIMUM_STRATEGIES, StrategyParams, IVault } from "src/interfaces/IVault.sol";
import { BaseStrategy, StrategyAPI } from "src/BaseStrategy.sol";
import { DateStrings } from "src/libraries/DateStrings.sol";
import { DecimalStrings } from "src/libraries/DecimalStrings.sol";

contract LogVault is Script {
    using DateStrings for uint256;
    using DecimalStrings for uint256;

    function run() public {
        address token = vm.envAddress("WETH");
        address governance = vm.envAddress("GOVERNANCE");
        address guardian = vm.envAddress("GUARDIAN");
        address rewards = vm.envAddress("REWARDS");
        address registry = vm.envAddress("REGISTRY");
        address vault = vm.envAddress("VAULT");
        address strategy = vm.envAddress("STRATEGY");

        vm.label(token, "WETH");
        vm.label(governance, "GOVERNANCE");
        vm.label(guardian, "GUARDIAN");
        vm.label(rewards, "REWARDS");
        vm.label(registry, "REGISTRY");
        vm.label(vault, "VAULT");
        vm.label(strategy, "STRATEGY");

        // Role Management
        console2.log("governance: ", IVault(vault).governance());
        console2.log("management: ", IVault(vault).management());
        console2.log("rewards: ", IVault(vault).rewards());
        console2.log("guardian: ", IVault(vault).guardian());

        // ERC20
        string memory name = IVault(vault).name();
        string memory symbol = IVault(vault).symbol();
        uint8 decimals = uint8(IVault(vault).decimals());
        console2.log("name: ", name);
        console2.log("symbol: ", symbol);
        console2.log("decimals: ", decimals);

        // Vault
        console2.log("apiVersion: ", IVault(vault).apiVersion());
        console2.log("activation: ", IVault(vault).activation().datetimeString());
        console2.log("token: ", IVault(vault).token());
        console2.log("depositLimit: ", IVault(vault).depositLimit().decimalString(decimals, false));
        console2.log("availableDepositLimit: ", IVault(vault).availableDepositLimit().decimalString(decimals, false));
        console2.log("totalIdle", IVault(vault).totalIdle().decimalString(decimals, false));
        console2.log("totalDebt: ", IVault(vault).totalDebt().decimalString(decimals, false));
        console2.log("totalAssets(totalIdle + totalDebt): ", IVault(vault).totalAssets().decimalString(decimals, false));
        console2.log("totalSupply: ", IVault(vault).totalSupply().decimalString(decimals, false));
        console2.log("pricePerShare: ", IVault(vault).pricePerShare().decimalString(decimals, false));
        console2.log("maxAvailableShares: ", IVault(vault).maxAvailableShares().decimalString(decimals, false));
        console2.log("managementFee: ", IVault(vault).managementFee().decimalString(4, true));
        console2.log("performanceFee: ", IVault(vault).performanceFee().decimalString(4, true));
        console2.log("emergencyShutdown: ", IVault(vault).emergencyShutdown());

        // Credit & Debt
        console2.log("debtRatio: ", IVault(vault).debtRatio().decimalString(4, true));
        console2.log("lockedProfit: ", IVault(vault).lockedProfit());
        console2.log("lockedProfitDegradation: ", IVault(vault).lockedProfitDegradation().decimalString(18, false));

        // Strategy
        for (uint256 i = 0; i < MAXIMUM_STRATEGIES; i++) {
            address withdrawal = IVault(vault).withdrawalQueue(i);
            if (withdrawal == address(0)) {
                break;
            }
            console2.log("index: ", i);
            console2.log("withdrawal: ", withdrawal);
        }

        address[] memory strategies = vm.envAddress("STRATEGIES", ",");
        for (uint256 i = 0; i < strategies.length; i++) {
            console2.log("index: ", i);
            console2.log("strategy: ", strategies[i]);

            StrategyParams memory params = IVault(vault).strategies(strategies[i]);
            console2.log("performanceFee: ", params.performanceFee.decimalString(4, true));
            console2.log("activation: ", params.activation.datetimeString());
            console2.log("debtRatio: ", params.debtRatio.decimalString(4, true));
            console2.log("minDebtPerHarvest: ", params.minDebtPerHarvest.decimalString(decimals, false));
            console2.log("maxDebtPerHarvest: ", params.maxDebtPerHarvest.decimalString(decimals, false));
            console2.log("lastReport: ", params.lastReport.datetimeString());
            console2.log("totalDebt: ", params.totalDebt.decimalString(decimals, false));
            console2.log("totalGain: ", params.totalGain.decimalString(decimals, false));
            console2.log("totalLoss: ", params.totalLoss.decimalString(decimals, false));

            console2.log(
                "debtOutstanding: ", IVault(vault).debtOutstanding(strategies[i]).decimalString(decimals, false)
            );
            console2.log("expectedReturn: ", IVault(vault).expectedReturn(strategies[i]).decimalString(decimals, false));
        }
    }
}

contract LogStrategy is Script {
    function run() public {
        address token = vm.envAddress("WETH");
        address governance = vm.envAddress("GOVERNANCE");
        address guardian = vm.envAddress("GUARDIAN");
        address rewards = vm.envAddress("REWARDS");
        address registry = vm.envAddress("REGISTRY");
        address vault = vm.envAddress("VAULT");
        address strategy = vm.envAddress("STRATEGY");

        vm.label(token, "WETH");
        vm.label(governance, "GOVERNANCE");
        vm.label(guardian, "GUARDIAN");
        vm.label(rewards, "REWARDS");
        vm.label(registry, "REGISTRY");
        vm.label(vault, "VAULT");
        vm.label(strategy, "STRATEGY");

        console2.log("name: ", BaseStrategy(strategy).name());
        console2.log("vault: ", StrategyAPI(strategy).vault());
        console2.log("want: ", address(BaseStrategy(strategy).want()));
        console2.log("strategist: ", BaseStrategy(strategy).strategist());
        console2.log("rewards: ", BaseStrategy(strategy).rewards());
        console2.log("keeper: ", BaseStrategy(strategy).keeper());

        console2.log("baseFeeOracle: ", BaseStrategy(strategy).baseFeeOracle());
        console2.log("healthCheck: ", BaseStrategy(strategy).healthCheck());
        console2.log("doHealthCheck: ", BaseStrategy(strategy).doHealthCheck());

        console2.log("minDebtPerHarvest: ", BaseStrategy(strategy).minReportDelay());
        console2.log("maxDebtPerHarvest: ", BaseStrategy(strategy).maxReportDelay());
        console2.log("creditThreshold: ", BaseStrategy(strategy).creditThreshold());

        console2.log("estimatedTotalAssets: ", BaseStrategy(strategy).estimatedTotalAssets());
        console2.log("delegatedAssets: ", BaseStrategy(strategy).delegatedAssets());

        console2.log("Vault strategy debtRatio: ", IVault(vault).strategies(strategy).debtRatio);
        console2.log("Vault strategy minDebtPerHarvest: ", IVault(vault).strategies(strategy).minDebtPerHarvest);
        console2.log("Vault strategy maxDebtPerHarvest: ", IVault(vault).strategies(strategy).maxDebtPerHarvest);
        console2.log("Vault strategy performanceFee: ", IVault(vault).strategies(strategy).performanceFee);

        console2.log("Vault strategy totalDebt: ", IVault(vault).strategies(strategy).totalDebt);
        console2.log("Vault strategy totalGain: ", IVault(vault).strategies(strategy).totalGain);
        console2.log("Vault strategy totalLoss: ", IVault(vault).strategies(strategy).totalLoss);
    }
}
