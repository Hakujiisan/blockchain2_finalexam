// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ItemVault is ERC4626, Ownable {
    event Harvested(uint256 amount);

    constructor(IERC20 asset)
        ERC4626(asset)
        ERC20("GameFi Vault Share", "gvSHARE")
        Ownable(msg.sender)
    {}

    function harvest(uint256 amount) external onlyOwner {
        require(
            IERC20(asset()).transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
        emit Harvested(amount);
    }
}