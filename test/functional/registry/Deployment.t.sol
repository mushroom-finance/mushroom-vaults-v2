// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { console2 } from "forge-std/src/console2.sol";

import { IRegistry } from "src/interfaces/IRegistry.sol";
import { IVault } from "src/interfaces/IVault.sol";

import { Fixture } from "test/shared/Fixture.sol";

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract DeploymentTest is Fixture {
    /// @dev A function invoked before each test case is run.
    function setUp() public override {
        // Instantiate the contract-under-test.
        super.setUp();
    }

    /// @dev Basic test. Run it with `forge test -vvv` to see the console log.
    function test_deployment_management() external {
        // No deployments yet for token
        vm.expectRevert();
        IRegistry(registry).latestVault(weth9);

        // Token tracking state variables should start off uninitialized
        assertEq(IRegistry(registry).tokens(0), address(0));
        assertEq(IRegistry(registry).numTokens(), 0);
        assertEq(IRegistry(registry).isRegistered(weth9), false);

        // New release does not add new token
        vm.prank(governance);
        IRegistry(registry).newRelease(vault);
        assertEq(IRegistry(registry).tokens(0), address(0));
        assertEq(IRegistry(registry).numTokens(), 0);
        assertEq(IRegistry(registry).isRegistered(weth9), false);

        // Creating the first deployment makes `latestVault()` work
        vm.prank(governance);
        IRegistry(registry).endorseVault(vault, 0);
        assertEq(IRegistry(registry).latestVault(weth9), vault);
        assertEq(IVault(vault).apiVersion(), "0.4.6");
        assertEq(IRegistry(registry).latestRelease(), "0.4.6");

        // Endorsing a vault with a new token registers a new token
        assertEq(IRegistry(registry).tokens(0), weth9);
        assertEq(IRegistry(registry).numTokens(), 1);
        assertEq(IRegistry(registry).isRegistered(weth9), true);

        // Can't deploy the same vault api version twice, proxy or not
        vm.expectRevert();
        vm.prank(governance);
        IRegistry(registry).newVault(weth9, guardian, rewards, "", "", 0);

        // You can deploy proxy Vaults, linked to a previous release
        vm.prank(governance);
        address proxy_vault2 = IRegistry(registry).newVault(usdt, guardian, rewards, "", "", 0);
        assertEq(IVault(proxy_vault2).apiVersion(), "0.4.6");
        assertEq(IVault(proxy_vault2).rewards(), rewards);
        assertEq(IVault(proxy_vault2).guardian(), guardian);
        assertEq(IRegistry(registry).latestVault(usdt), proxy_vault2);

        // Adding a new endorsed vault with `newVault()` registers a new token
        assertEq(IRegistry(registry).tokens(0), weth9);
        assertEq(IRegistry(registry).tokens(1), usdt);
        assertEq(IRegistry(registry).numTokens(), 2);
        assertEq(IRegistry(registry).isRegistered(weth9), true);
        assertEq(IRegistry(registry).isRegistered(usdt), true);

        // Not just anyone can create a new endorsed Vault, only governance can!
        vm.expectRevert();
        IRegistry(registry).newVault(token, guardian, rewards, "", "", 0);
    }

    /// @dev Fuzz test that provides random values for an unsigned integer, but which rejects zero as an input.
    /// If you need more sophisticated input validation, you should use the `bound` utility instead.
    /// See https://twitter.com/PaulRBerg/status/1622558791685242880

    /// @dev Fork test that runs against an Ethereum Mainnet fork. For this to work, you need to set `API_KEY_ALCHEMY`
    /// in your environment You can get an API key for free at https://alchemy.com.
}
