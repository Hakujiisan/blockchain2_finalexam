// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin-upgradeable/contracts/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

contract GameItemsV1 is
    Initializable,
    ERC1155Upgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant MINTER_ROLE   = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    uint256 public constant GOLD   = 1;
    uint256 public constant WOOD   = 2;
    uint256 public constant IRON   = 3;

    uint256 public constant LEGENDARY_SWORD = 1000;

    mapping(uint256 => uint256) public maxSupply;
    mapping(uint256 => uint256) public totalMinted;

    event CraftCompleted(address indexed player, uint256 indexed outputId, uint256 amount);

    constructor() { _disableInitializers(); }

    function initialize(address admin) public initializer {
        __ERC1155_init("https://api.gamefi.com/items/{id}.json");
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);

        maxSupply[LEGENDARY_SWORD] = 100;
    }

    function mint(address to, uint256 id, uint256 amount)
        external onlyRole(MINTER_ROLE)
    {
        if (maxSupply[id] > 0) {
            require(totalMinted[id] + amount <= maxSupply[id], "Exceeds max supply");
        }
        totalMinted[id] += amount;
        _mint(to, id, amount, "");
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

    function version() external pure virtual returns (string memory) {
        return "V1";
    }

    function _authorizeUpgrade(address newImplementation)
        internal override onlyRole(UPGRADER_ROLE) {}

    function supportsInterface(bytes4 interfaceId)
        public view override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}