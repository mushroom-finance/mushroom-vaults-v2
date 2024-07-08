// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { console2 } from "forge-std/src/console2.sol";

import { IRegistry } from "src/interfaces/IRegistry.sol";
import { IVault } from "src/interfaces/IVault.sol";
import { BaseStrategy, BaseStrategyInitializable } from "src/BaseStrategy.sol";

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
    function test_strategy_deployment() external view {
        assertEq(BaseStrategy(strategy).strategist(), strategist);
        assertEq(BaseStrategy(strategy).rewards(), strategist);
        assertEq(BaseStrategy(strategy).keeper(), strategist);
        assertEq(address(BaseStrategy(strategy).want()), IVault(vault).token());
        assertEq(BaseStrategy(strategy).apiVersion(), "0.4.6");
        assertEq(BaseStrategy(strategy).name(), "TestStrategy 0.4.6");
        assertEq(BaseStrategy(strategy).delegatedAssets(), 0);

        assertEq(BaseStrategy(strategy).emergencyExit(), false);

        // Should not trigger until it is approved
        assertEq(BaseStrategy(strategy).harvestTrigger(0), false);
        assertEq(BaseStrategy(strategy).tendTrigger(0), false);
    }

    function test_strategy_no_reinit() external {
        vm.expectRevert("Strategy already initialized");
        BaseStrategyInitializable(strategy).initialize(vault, strategist, strategist, strategist);
    }

    function test_strategy_setEmergencyExit() external {
        // Only governance or strategist can set this param
        vm.expectRevert();
        vm.prank(userA);
        BaseStrategy(strategy).setEmergencyExit();
        assertEq(BaseStrategy(strategy).emergencyExit(), false);

        vm.prank(governance); // vault.governance()
        // vm.prank(strategist);
        BaseStrategy(strategy).setEmergencyExit();
        assertEq(BaseStrategy(strategy).emergencyExit(), true);
    }

    function test_strategy_harvest_permission() external {
        vm.prank(strategist);
        BaseStrategy(strategy).setKeeper(keeper);
        vm.prank(governance);
        IVault(vault).addStrategy(
            strategy,
            4000, // 40% of Vault
            0, // Minimum debt increase per harvest
            2 ** 256 - 1, // maximum debt increase per harvest
            1000 // 10% performance fee for Strategist
        );

        vm.prank(governance);
        BaseStrategy(strategy).harvest();
    }

    /// @dev Fuzz test that provides random values for an unsigned integer, but which rejects zero as an input.
    /// If you need more sophisticated input validation, you should use the `bound` utility instead.
    /// See https://twitter.com/PaulRBerg/status/1622558791685242880

    /// @dev Fork test that runs against an Ethereum Mainnet fork. For this to work, you need to set `API_KEY_ALCHEMY`
    /// in your environment You can get an API key for free at https://alchemy.com.
}
