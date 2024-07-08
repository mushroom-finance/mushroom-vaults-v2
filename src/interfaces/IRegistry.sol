// SPDX-License-Identifier: MIT
pragma solidity =0.8.23;

interface IRegistry {
    function pendingGovernance() external view returns (address);
    function governance() external view returns (address);
    function setGovernance(address governance) external;
    function acceptGovernance() external;

    function numReleases() external view returns (uint256);
    function latestRelease() external view returns (string memory);
    function newRelease(address vault) external;

    function latestVault(address token) external view returns (address);

    function tokens(uint256 index) external view returns (address);
    function numTokens() external view returns (uint256);
    function isRegistered(address token) external view returns (bool);
    function newExperimentalVault(
        address token,
        address governance,
        address guardian,
        address rewards,
        string memory name,
        string memory symbol,
        uint256 releaseDelta
    )
        external
        returns (address);
    function newVault(
        address token,
        address guardian,
        address rewards,
        string memory name,
        string memory symbol,
        uint256 releaseDelta
    )
        external
        returns (address);
    function endorseVault(address vault, uint256 releaseDelta) external;

    function banksy(address tagger) external view returns (bool);
    function setBanksy(address tagger, bool allowed) external;
    function tags(address vault) external view returns (string memory);
    function tagVault(address vault, string memory tag) external;
}
