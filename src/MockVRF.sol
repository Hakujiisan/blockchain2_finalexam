// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IGameItems {
    function mint(address to, uint256 id, uint256 amount) external;
}

contract LootBox is Ownable {
    IGameItems public immutable gameItems;

    uint256 public constant LEGENDARY_SWORD = 1000;
    uint256 public constant DRAGON_SHIELD   = 1001;
    uint256 public constant MAGIC_STAFF     = 1002;

    uint256 private _nonce;

    event LootDropped(address indexed player, uint256 itemId);

    constructor(address _gameItems) Ownable(msg.sender) {
        gameItems = IGameItems(_gameItems);
    }

    function openLootBox() external {
        uint256 rand = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            msg.sender,
            _nonce++
        ))) % 3;

        uint256 itemId;
        if (rand == 0) itemId = LEGENDARY_SWORD;
        else if (rand == 1) itemId = DRAGON_SHIELD;
        else itemId = MAGIC_STAFF;

        gameItems.mint(msg.sender, itemId, 1);
        emit LootDropped(msg.sender, itemId);
    }
}