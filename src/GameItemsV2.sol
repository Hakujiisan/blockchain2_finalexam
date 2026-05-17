// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./GameItemsV1.sol";

contract GameItemsV2 is GameItemsV1 {
    uint256 public constant CRYSTAL = 4;
    uint256 public dropRate;

    event DropRateUpdated(uint256 newRate);

    function initializeV2(uint256 _dropRate) external reinitializer(2) {
        dropRate = _dropRate;
    }

    function setDropRate(uint256 _dropRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        dropRate = _dropRate;
        emit DropRateUpdated(_dropRate);
    }

    function version() external pure override returns (string memory) {
        return "V2";
    }
}
