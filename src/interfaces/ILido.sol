// SPDX-License-Identifier: MIT
pragma solidity =0.8.23;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILido is IERC20 {
    event Submitted(address indexed sender, uint256 amount, address referral);

    function submit(address _referral) external payable returns (uint256);
}
