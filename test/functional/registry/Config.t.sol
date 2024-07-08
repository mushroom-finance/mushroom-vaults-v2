// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { console2 } from "forge-std/src/console2.sol";

import { IRegistry } from "src/interfaces/IRegistry.sol";
import { IVault } from "src/interfaces/IVault.sol";

import { Fixture } from "test/shared/Fixture.sol";

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract ConfigTest is Fixture {
    /// @dev A function invoked before each test case is run.
    function setUp() public override {
        // Instantiate the contract-under-test.
        super.setUp();
    }

    /// @dev Basic test. Run it with `forge test -vvv` to see the console log.
    function test_registry_deployment() external view {
        assertEq(IRegistry(registry).governance(), governance);
        assertEq(IRegistry(registry).numReleases(), 0);
    }

    function test_registry_setGovernance() external {
        // No one can set governance but governance
        vm.expectRevert();
        vm.prank(newGovernance);
        IRegistry(registry).setGovernance(newGovernance);

        // Governance doesn't change until it's accepted
        vm.prank(governance);
        IRegistry(registry).setGovernance(newGovernance);
        assertEq(IRegistry(registry).pendingGovernance(), newGovernance);
        assertEq(IRegistry(registry).governance(), governance);

        // Only new governance can accept a change of governance
        vm.expectRevert();
        vm.prank(governance);
        IRegistry(registry).acceptGovernance();

        // Governance doesn't change until it's accepted
        vm.prank(newGovernance);
        IRegistry(registry).acceptGovernance();
        assertEq(IRegistry(registry).governance(), newGovernance);

        // No one can set governance but governance
        vm.expectRevert();
        vm.prank(governance);
        IRegistry(registry).setGovernance(newGovernance);

        // Only new governance can accept a change of governance
        vm.expectRevert();
        vm.prank(governance);
        IRegistry(registry).acceptGovernance();
    }

    function test_banksy() external {
        vm.prank(governance);
        IRegistry(registry).newRelease(vault);
        assertEq(IRegistry(registry).tags(vault), "");

        // Not just anyone can tag a Vault, only a Banksy can!
        vm.expectRevert();
        vm.prank(userA);
        IRegistry(registry).tagVault(vault, "Anything I want!");

        // Not just anyone can become a banksy either
        vm.expectRevert();
        vm.prank(userA);
        IRegistry(registry).setBanksy(userA, true);

        assertEq(IRegistry(registry).banksy(userA), false);
        vm.prank(governance);
        IRegistry(registry).setBanksy(userA, true);
        assertEq(IRegistry(registry).banksy(userA), true);

        vm.prank(userA);
        IRegistry(registry).tagVault(vault, "Anything I want!");
        assertEq(IRegistry(registry).tags(vault), "Anything I want!");

        vm.prank(governance);
        IRegistry(registry).setBanksy(userA, false);
        vm.expectRevert();
        vm.prank(userA);
        IRegistry(registry).tagVault(vault, "");

        assertEq(IRegistry(registry).banksy(governance), false);
        vm.prank(governance);
        IRegistry(registry).tagVault(vault, "");
    }

    /// @dev Fuzz test that provides random values for an unsigned integer, but which rejects zero as an input.
    /// If you need more sophisticated input validation, you should use the `bound` utility instead.
    /// See https://twitter.com/PaulRBerg/status/1622558791685242880

    /// @dev Fork test that runs against an Ethereum Mainnet fork. For this to work, you need to set `API_KEY_ALCHEMY`
    /// in your environment You can get an API key for free at https://alchemy.com.
}
