// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract GameItems is ERC1155, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public constant GOLD    = 1;
    uint256 public constant WOOD    = 2;
    uint256 public constant IRON    = 3;
    uint256 public constant CRYSTAL = 4;

    uint256 public constant LEGENDARY_SWORD = 1000;
    uint256 public constant DRAGON_SHIELD   = 1001;
    uint256 public constant MAGIC_STAFF     = 1002;

    mapping(uint256 => uint256) public maxSupply;
    mapping(uint256 => uint256) public totalMinted;

    event CraftCompleted(address indexed player, uint256 indexed outputId, uint256 amount);

    constructor() ERC1155("https://api.gamefi.com/items/{id}.json") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        maxSupply[LEGENDARY_SWORD] = 100;
        maxSupply[DRAGON_SHIELD]   = 100;
        maxSupply[MAGIC_STAFF]     = 100;
    }

    function mint(address to, uint256 id, uint256 amount) external onlyRole(MINTER_ROLE) {
        if (maxSupply[id] > 0) {
            require(totalMinted[id] + amount <= maxSupply[id], "Exceeds max supply");
        }
        totalMinted[id] += amount;
        _mint(to, id, amount, "");
    }

    function mintBatch(address to, uint256[] calldata ids, uint256[] calldata amounts)
        external onlyRole(MINTER_ROLE)
    {
        for (uint256 i = 0; i < ids.length; i++) {
            if (maxSupply[ids[i]] > 0) {
                require(totalMinted[ids[i]] + amounts[i] <= maxSupply[ids[i]], "Exceeds max supply");
                totalMinted[ids[i]] += amounts[i];
            }
        }
        _mintBatch(to, ids, amounts, "");
    }

    function craft(
        uint256[] calldata inputIds,
        uint256[] calldata inputAmounts,
        uint256 outputId,
        uint256 outputAmount
    ) external {
        _burnBatch(msg.sender, inputIds, inputAmounts);
        if (maxSupply[outputId] > 0) {
            require(totalMinted[outputId] + outputAmount <= maxSupply[outputId], "Exceeds max supply");
            totalMinted[outputId] += outputAmount;
        }
        _mint(msg.sender, outputId, outputAmount, "");
        emit CraftCompleted(msg.sender, outputId, outputAmount);
    }

    function uri(uint256 id) public pure override returns (string memory) {
        return string(abi.encodePacked(
            "https://api.gamefi.com/items/",
            Strings.toString(id),
            ".json"
        ));
    }

    function supportsInterface(bytes4 interfaceId)
        public view override(ERC1155, AccessControl) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
