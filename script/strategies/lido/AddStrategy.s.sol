// SPDX-License-Identifier: MIT
pragma solidity =0.8.23;

import { Script, console2 } from "forge-std/src/Script.sol";
import { VyperDeployer } from "Foundry-Vyper/VyperDeployer.sol";
import { IRegistry } from "src/interfaces/IRegistry.sol";
import { IVault } from "src/interfaces/IVault.sol";
import { Strategy } from "src/strategies/lido/Strategy.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract AddStrategy is Script {
    function run() public returns (address strategy) {
        uint256 broadcaster = vm.envUint("BROADCASTER");
        address vault = vm.envAddress("VAULT");
        address token = vm.envAddress("WETH");

        vm.label(vault, "VAULT");
        vm.label(token, "WETH");

        vm.startBroadcast(broadcaster);
        strategy = address(new Strategy(vault));
        vm.label(strategy, "STRATEGY");

        IVault(vault).addStrategy(strategy, 8000, 0, 10 ** 21, 1000);
        vm.stopBroadcast();
    }
}
