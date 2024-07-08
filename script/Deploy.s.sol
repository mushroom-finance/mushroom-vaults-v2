// SPDX-License-Identifier: MIT
pragma solidity =0.8.23;

import { Script, console2 } from "forge-std/src/Script.sol";
import { VyperDeployer } from "Foundry-Vyper/VyperDeployer.sol";
import { IRegistry } from "src/interfaces/IRegistry.sol";
import { IVault } from "src/interfaces/IVault.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeployRegistry is VyperDeployer, Script {
    function run() public returns (address registry) {
        uint256 broadcaster = vm.envUint("BROADCASTER");

        vm.startBroadcast(broadcaster);
        registry = deploy("src/", "Registry");
        vm.stopBroadcast();
    }
}

contract DeployVault is VyperDeployer, Script {
    function run() public returns (address vault) {
        uint256 broadcaster = vm.envUint("BROADCASTER");
        address registry = vm.envAddress("REGISTRY");
        vm.label(registry, "REGISTRY");

        vm.startBroadcast(broadcaster);
        vault = deploy("src/", "Vault");
        vm.label(vault, "VAULT");

        IRegistry(registry).newRelease(vault);
        console2.log(IRegistry(registry).latestRelease());
        vm.stopBroadcast();
    }
}
