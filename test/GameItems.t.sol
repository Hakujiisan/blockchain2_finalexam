// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/GameItems.sol";

contract GameItemsTest is Test {
    GameItems public items;
    address public admin = address(this);
    address public player1 = makeAddr("player1");
    address public player2 = makeAddr("player2");

    uint256 constant GOLD = 1;
    uint256 constant WOOD = 2;
    uint256 constant IRON = 3;
    uint256 constant LEGENDARY_SWORD = 1000;
    uint256 constant DRAGON_SHIELD = 1001;

    function setUp() public {
        items = new GameItems();
        items.grantRole(items.MINTER_ROLE(), address(this));
    }

    function test_MintGold() public {
        items.mint(player1, GOLD, 100);
        assertEq(items.balanceOf(player1, GOLD), 100);
    }

    function test_MintBatch() public {
        uint256[] memory ids = new uint256[](3);
        uint256[] memory amounts = new uint256[](3);
        ids[0] = GOLD; amounts[0] = 500;
        ids[1] = WOOD; amounts[1] = 300;
        ids[2] = IRON; amounts[2] = 100;
        items.mintBatch(player1, ids, amounts);
        assertEq(items.balanceOf(player1, GOLD), 500);
        assertEq(items.balanceOf(player1, WOOD), 300);
        assertEq(items.balanceOf(player1, IRON), 100);
    }

    function test_Crafting() public {
        items.mint(player1, GOLD, 100);
        items.mint(player1, WOOD, 50);
        items.mint(player1, IRON, 10);

        uint256[] memory inputIds = new uint256[](3);
        uint256[] memory inputAmounts = new uint256[](3);
        inputIds[0] = GOLD; inputAmounts[0] = 100;
        inputIds[1] = WOOD; inputAmounts[1] = 50;
        inputIds[2] = IRON; inputAmounts[2] = 10;

        vm.prank(player1);
        items.craft(inputIds, inputAmounts, LEGENDARY_SWORD, 1);

        assertEq(items.balanceOf(player1, GOLD), 0);
        assertEq(items.balanceOf(player1, LEGENDARY_SWORD), 1);
    }

    function test_CraftingExceedsMaxSupply() public {
        items.mint(player1, GOLD, 100);
        items.mint(player1, WOOD, 50);
        items.mint(player1, IRON, 10);
        items.mint(player2, GOLD, 100);
        items.mint(player2, WOOD, 50);
        items.mint(player2, IRON, 10);

        uint256[] memory inputIds = new uint256[](3);
        uint256[] memory inputAmounts = new uint256[](3);
        inputIds[0] = GOLD; inputAmounts[0] = 100;
        inputIds[1] = WOOD; inputAmounts[1] = 50;
        inputIds[2] = IRON; inputAmounts[2] = 10;

        vm.prank(player1);
        items.craft(inputIds, inputAmounts, LEGENDARY_SWORD, 100);

        vm.expectRevert("Exceeds max supply");
        vm.prank(player2);
        items.craft(inputIds, inputAmounts, LEGENDARY_SWORD, 1);
    }

    function test_SafeTransfer() public {
        items.mint(player1, GOLD, 100);
        vm.prank(player1);
        items.safeTransferFrom(player1, player2, GOLD, 40, "");
        assertEq(items.balanceOf(player1, GOLD), 60);
        assertEq(items.balanceOf(player2, GOLD), 40);
    }

    function test_OnlyMinterCanMint() public {
        vm.expectRevert();
        vm.prank(player1);
        items.mint(player1, GOLD, 100);
    }

    function test_URI() public view {
        string memory uri = items.uri(GOLD);
        assertEq(uri, "https://api.gamefi.com/items/1.json");
    }

    function test_BatchTransfer() public {
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        ids[0] = GOLD; amounts[0] = 100;
        ids[1] = WOOD; amounts[1] = 50;
        items.mintBatch(player1, ids, amounts);

        uint256[] memory transferAmounts = new uint256[](2);
        transferAmounts[0] = 30;
        transferAmounts[1] = 20;

        vm.prank(player1);
        items.safeBatchTransferFrom(player1, player2, ids, transferAmounts, "");
        assertEq(items.balanceOf(player1, GOLD), 70);
        assertEq(items.balanceOf(player2, GOLD), 30);
    }

    function test_InsufficientBalanceTransfer() public {
        items.mint(player1, GOLD, 10);
        vm.expectRevert();
        vm.prank(player1);
        items.safeTransferFrom(player1, player2, GOLD, 999, "");
    }

    function test_TotalMinted() public {
        items.mint(player1, GOLD, 100);
        items.mint(player2, GOLD, 50);
        assertEq(items.totalMinted(GOLD), 150);
    }

    function test_BalanceOfBatch() public {
        items.mint(player1, GOLD, 100);
        items.mint(player2, WOOD, 200);
        address[] memory accounts = new address[](2);
        uint256[] memory tokenIds = new uint256[](2);
        accounts[0] = player1; tokenIds[0] = GOLD;
        accounts[1] = player2; tokenIds[1] = WOOD;
        uint256[] memory balances = items.balanceOfBatch(accounts, tokenIds);
        assertEq(balances[0], 100);
        assertEq(balances[1], 200);
    }
}