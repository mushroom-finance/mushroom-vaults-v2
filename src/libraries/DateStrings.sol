// SPDX-License-Identifier: MIT
pragma solidity =0.8.23;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { DateTime } from "solidity-datetime/contracts/DateTime.sol";

library DateStrings {
    using Strings for uint256;

    function dateString(uint256 timestamp) internal pure returns (string memory) {
        (uint256 year, uint256 month, uint256 day) = DateTime.timestampToDate(timestamp);

        bytes memory concatenatedBytes = abi.encodePacked(year.toString(), "-", month.toString(), "-", day.toString());

        return string(concatenatedBytes);
    }

    function datetimeString(uint256 timestamp) internal pure returns (string memory) {
        (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second) =
            DateTime.timestampToDateTime(timestamp);

        bytes memory concatenatedBytes = abi.encodePacked(
            year.toString(),
            "-",
            month.toString(),
            "-",
            day.toString(),
            " ",
            hour.toString(),
            ":",
            minute.toString(),
            ":",
            second.toString()
        );

        return string(concatenatedBytes);
    }
}
