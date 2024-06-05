// SPDX-License-Identifier: MIT
pragma solidity =0.8.23;

interface IRegistry {
    function latestRelease() external view returns (string memory);
    function numReleases() external view returns (uint256);
    function newRelease(address vault) external;

    function newExperimentalVault(
        address token,
        address governance,
        address guardian,
        address rewards,
        string memory name,
        string memory symbol
    )
        external
        returns (address);
}
