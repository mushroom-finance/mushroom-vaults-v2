// SPDX-License-Identifier: MIT
pragma solidity =0.8.23;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Constants
uint256 constant MAXIMUM_STRATEGIES = 20;

struct StrategyParams {
    uint256 performanceFee;
    uint256 activation;
    uint256 debtRatio;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
}

interface IVault is IERC20 {
    // ERC20
    function name() external view returns (string calldata);
    function symbol() external view returns (string calldata);
    function decimals() external view returns (uint256);

    // Vault
    function apiVersion() external pure returns (string memory);
    function activation() external view returns (uint256);
    function token() external view returns (address);
    function depositLimit() external view returns (uint256);
    function availableDepositLimit() external view returns (uint256);
    function totalIdle() external view returns (uint256);
    function totalDebt() external view returns (uint256);
    function totalAssets() external view returns (uint256);
    function pricePerShare() external view returns (uint256);
    function maxAvailableShares() external view returns (uint256);
    function managementFee() external view returns (uint256);
    function setManagementFee(uint256 fee) external;
    function performanceFee() external view returns (uint256);
    function setPerformanceFee(uint256 fee) external;
    function emergencyShutdown() external view returns (bool);
    function setEmergencyShutdown(bool active) external;

    // Credit & Debt
    function debtRatio() external view returns (uint256);
    function lockedProfitDegradation() external view returns (uint256);
    function lockedProfit() external view returns (uint256);

    // Strategy
    function withdrawalQueue(uint256 index) external view returns (address);
    function strategies(address _strategy) external view returns (StrategyParams memory);
    /**
     * View how much the Vault would like to pull back from the Strategy,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function debtOutstanding() external view returns (uint256);
    function debtOutstanding(address _strategy) external view returns (uint256);
    /**
     * View how much the Vault expect this Strategy to return at the current
     * block, based on its present performance (since its last report). Can be
     * used to determine expectedReturn in your Strategy.
     */
    function expectedReturn() external view returns (uint256);
    function expectedReturn(address _strategy) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 expiry,
        bytes calldata signature
    )
        external
        returns (bool);

    function initialize(
        address token,
        address governance,
        address rewards,
        string memory name,
        string memory symbol,
        address guardian,
        address management
    )
        external;

    function addStrategy(
        address _strategy,
        uint256 _debtRatio,
        uint256 _minDebtPerHarvest,
        uint256 _maxDebtPerHarvest,
        uint256 _performanceFee
    )
        external;

    function setDepositLimit(uint256 amount) external;

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function deposit() external returns (uint256);

    function deposit(uint256 amount) external returns (uint256);

    function deposit(uint256 amount, address recipient) external returns (uint256);

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function withdraw() external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);

    function withdraw(uint256 maxShares, address recipient) external returns (uint256);

    /**
     * View how much the Vault would increase this Strategy's borrow limit,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function creditAvailable() external view returns (uint256);

    /**
     * This is the main contact point where the Strategy interacts with the
     * Vault. It is critical that this call is handled as intended by the
     * Strategy. Therefore, this function will be called by BaseStrategy to
     * make sure the integration is correct.
     */
    function report(uint256 _gain, uint256 _loss, uint256 _debtPayment) external returns (uint256);

    /**
     * This function should only be used in the scenario where the Strategy is
     * being retired but no migration of the positions are possible, or in the
     * extreme scenario that the Strategy needs to be put into "Emergency Exit"
     * mode in order for it to exit as quickly as possible. The latter scenario
     * could be for any reason that is considered "critical" that the Strategy
     * exits its position as fast as possible, such as a sudden change in
     * market conditions leading to losses, or an imminent failure in an
     * external dependency.
     */
    function revokeStrategy() external;

    function revokeStrategy(address strategy) external;

    function migrateStrategy(address oldVersion, address newVersion) external;

    function updateStrategyPerformanceFee(address strategy, uint256 performanceFee) external;

    function updateStrategyMinDebtPerHarvest(address strategy, uint256 minDebtPerHarvest) external;

    function updateStrategyMaxDebtPerHarvest(address strategy, uint256 maxDebtPerHarvest) external;

    function updateStrategyDebtRatio(address strategy, uint256 debtRatio) external;

    function withdraw(uint256 maxShare, address recipient, uint256 maxLoss) external;

    /**
     * View the governance address of the Vault to assert privileged functions
     * can only be called by governance. The Strategy serves the Vault, so it
     * is subject to governance defined by the Vault.
     */
    function governance() external view returns (address);

    /**
     * View the management address of the Vault to assert privileged functions
     * can only be called by management. The Strategy serves the Vault, so it
     * is subject to management defined by the Vault.
     */
    function management() external view returns (address);

    /**
     * View the guardian address of the Vault to assert privileged functions
     * can only be called by guardian. The Strategy serves the Vault, so it
     * is subject to guardian defined by the Vault.
     */
    function guardian() external view returns (address);

    function rewards() external view returns (address);
}
