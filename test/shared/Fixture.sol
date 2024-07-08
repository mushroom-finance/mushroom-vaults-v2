// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.23;

import { Test } from "forge-std/src/Test.sol";
import { ERC20PresetFixedSupply } from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";

import { VyperDeployer } from "Foundry-Vyper/VyperDeployer.sol";
import { IVault } from "src/interfaces/IVault.sol";
import { TestStrategy } from "src/strategies/test/TestStrategy.sol";

import { WETH } from "./WETH.sol";

contract Fixture is VyperDeployer, Test {
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000_000 ether;
    uint256 public constant TEST_AMOUNT = 100 ether;

    address public faucet = vm.addr(1);
    address public governance = vm.addr(2);
    address public newGovernance = vm.addr(3);
    address public guardian = vm.addr(4);
    address public management = vm.addr(5);
    address public rewards = vm.addr(6);
    address public strategist = vm.addr(7);
    address public keeper = vm.addr(8);
    address public userA = vm.addr(9);
    address public userB = vm.addr(10);
    address public userC = vm.addr(11);

    address internal weth9;
    address internal usdt;
    address internal token;

    address internal registry;
    address internal vault;
    address internal strategy;

    function setUp() public virtual {
        // vm.chainId(31_337);

        vm.label(faucet, "Faucet");
        vm.label(governance, "Governance");
        vm.label(newGovernance, "NewGovernance");
        vm.label(guardian, "Guardian");
        vm.label(management, "Management");
        vm.label(rewards, "Rewards");
        vm.label(strategist, "Strategist");
        vm.label(keeper, "Keeper");
        vm.label(userA, "UserA");
        vm.label(userB, "UserB");
        vm.label(userC, "UserC");

        weth9 = address(new WETH());
        usdt = address(new ERC20PresetFixedSupply("USDT", "USDT", TOTAL_SUPPLY, faucet));
        token = address(new ERC20PresetFixedSupply("TOKEN", "UNIT", TOTAL_SUPPLY, faucet));
        vm.label(weth9, "WETH");
        vm.label(usdt, "USDT");
        vm.label(token, "Token");

        vm.prank(governance);
        registry = deploy("src/", "Registry");
        vm.label(registry, "Registry");

        vm.prank(guardian);
        vault = deploy("src/", "Vault");
        vm.label(vault, "Vault");
        IVault(vault).initialize(weth9, governance, rewards, "WBTC mVault", "mvWBTC", guardian, management);
        vm.prank(governance);
        IVault(vault).setDepositLimit(type(uint256).max);

        vm.prank(strategist);
        strategy = address(new TestStrategy(vault));
        vm.label(strategy, "Strategy");
    }
}
