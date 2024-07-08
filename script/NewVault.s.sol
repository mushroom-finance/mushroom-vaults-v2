// SPDX-License-Identifier: MIT
pragma solidity =0.8.23;

import { Script } from "forge-std/src/Script.sol";
import { VyperDeployer } from "Foundry-Vyper/VyperDeployer.sol";
import { IRegistry } from "src/interfaces/IRegistry.sol";
import { IVault } from "src/interfaces/IVault.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract NewVault is VyperDeployer, Script {
    function run() public returns (address vault) {
        uint256 broadcaster = vm.envUint("BROADCASTER");
        address token = vm.envAddress("WETH");
        address governance = vm.envAddress("GOVERNANCE");
        address guardian = vm.envAddress("GUARDIAN");
        address rewards = vm.envAddress("REWARDS");
        address registry = vm.envAddress("REGISTRY");
        string memory name = "WETH mVault";
        string memory symbol = "mvWETH";

        vm.label(token, "WETH");
        vm.label(governance, "GOVERNANCE");
        vm.label(guardian, "GUARDIAN");
        vm.label(rewards, "REWARDS");
        vm.label(registry, "REGISTRY");

        vm.startBroadcast(broadcaster);
        vault = IRegistry(registry).newVault(token, guardian, rewards, name, symbol, 0);
        vm.stopBroadcast();
    }
}
