// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { console2 } from "forge-std/src/console2.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

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
    function test_vault_deployment() external {
        // Deploy the Vault without any name/symbol overrides
        vm.prank(guardian);
        address vault2 = deploy("src/", "Vault");
        vm.label(vault2, "Vault2");
        string memory symbol = IERC20Metadata(token).symbol();
        IVault(vault2).initialize(
            token,
            governance,
            rewards,
            string.concat(symbol, " mVault"),
            string.concat("mv", symbol),
            guardian,
            guardian
        );

        // Addresses
        assertEq(IVault(vault2).governance(), governance);
        assertEq(IVault(vault2).management(), guardian);
        assertEq(IVault(vault2).guardian(), guardian);
        assertEq(IVault(vault2).rewards(), rewards);
        assertEq(IVault(vault2).token(), token);

        // UI Stuff
        assertEq(IVault(vault2).name(), string.concat(symbol, " mVault"));
        assertEq(IVault(vault2).symbol(), string.concat("mv", symbol));
        assertEq(IVault(vault2).decimals(), IERC20Metadata(token).decimals());
        assertEq(IVault(vault2).apiVersion(), "0.4.6");
        assertEq(IVault(vault2).debtRatio(), 0);
        assertEq(IVault(vault2).depositLimit(), 0);
        assertEq(IVault(vault2).creditAvailable(), 0);
        assertEq(IVault(vault2).debtOutstanding(), 0);
        assertEq(IVault(vault2).maxAvailableShares(), 0);
        assertEq(IVault(vault2).totalAssets(), 0);
        assertEq(IVault(vault2).pricePerShare() / 10 ** IVault(vault2).decimals(), 1.0);
    }

    /// @dev Fuzz test that provides random values for an unsigned integer, but which rejects zero as an input.
    /// If you need more sophisticated input validation, you should use the `bound` utility instead.
    /// See https://twitter.com/PaulRBerg/status/1622558791685242880

    /// @dev Fork test that runs against an Ethereum Mainnet fork. For this to work, you need to set `API_KEY_ALCHEMY`
    /// in your environment You can get an API key for free at https://alchemy.com.
}
