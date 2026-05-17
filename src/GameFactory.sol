// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./GameItems.sol";
import "./ItemVault.sol";

contract GameFactory is Ownable {
    address[] public deployedItems;
    address[] public deployedVaults;

    event ItemsDeployed(address indexed items, uint256 indexed index);
    event VaultDeployed(address indexed vault, address indexed asset);

    constructor() Ownable(msg.sender) {}

    function deployItems() external onlyOwner returns (address) {
        GameItems items = new GameItems();
        items.grantRole(items.DEFAULT_ADMIN_ROLE(), msg.sender);
        deployedItems.push(address(items));
        emit ItemsDeployed(address(items), deployedItems.length - 1);
        return address(items);
    }

    function deployItemsDeterministic(bytes32 salt) external onlyOwner returns (address) {
        GameItems items = new GameItems{salt: salt}();
        items.grantRole(items.DEFAULT_ADMIN_ROLE(), msg.sender);
        deployedItems.push(address(items));
        emit ItemsDeployed(address(items), deployedItems.length - 1);
        return address(items);
    }

    function deployVault(address asset) external onlyOwner returns (address) {
        ItemVault vault = new ItemVault(IERC20(asset));
        deployedVaults.push(address(vault));
        emit VaultDeployed(address(vault), asset);
        return address(vault);
    }

    function predictAddress(bytes32 salt) external view returns (address) {
        bytes32 hash =
            keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(type(GameItems).creationCode)));
        return address(uint160(uint256(hash)));
    }

    function getDeployedItems() external view returns (address[] memory) {
        return deployedItems;
    }

    function getDeployedVaults() external view returns (address[] memory) {
        return deployedVaults;
    }
}
