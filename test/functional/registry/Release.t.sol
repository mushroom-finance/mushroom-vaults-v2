// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { console2 } from "forge-std/src/console2.sol";

import { IRegistry } from "src/interfaces/IRegistry.sol";
import { IVault } from "src/interfaces/IVault.sol";

import { Fixture } from "test/shared/Fixture.sol";

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract ReleaseTest is Fixture {
    /// @dev A function invoked before each test case is run.
    function setUp() public override {
        // Instantiate the contract-under-test.
        super.setUp();
    }

    /// @dev Basic test. Run it with `forge test -vvv` to see the console log.
    function test_release_management() external {
        // No releases yet
        vm.expectRevert();
        IRegistry(registry).latestRelease();

        // Not just anyone can create a new Release
        vm.expectRevert();
        vm.prank(userA);
        IRegistry(registry).newRelease(vault);

        // Creating the first release makes `latestRelease()` work
        vm.prank(governance);
        IRegistry(registry).newRelease(vault);
        assertEq(IVault(vault).apiVersion(), "0.4.6");
        assertEq(IRegistry(registry).latestRelease(), "0.4.6");

        // Can't release same vault twice (cannot have the same api version)
        vm.expectRevert();
        vm.prank(governance);
        IRegistry(registry).newRelease(vault);
    }

    /// @dev Fuzz test that provides random values for an unsigned integer, but which rejects zero as an input.
    /// If you need more sophisticated input validation, you should use the `bound` utility instead.
    /// See https://twitter.com/PaulRBerg/status/1622558791685242880

    /// @dev Fork test that runs against an Ethereum Mainnet fork. For this to work, you need to set `API_KEY_ALCHEMY`
    /// in your environment You can get an API key for free at https://alchemy.com.
}
