// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/ItemVault.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor() ERC20("Mock", "MCK") {}
    function mint(address to, uint256 amount) external { _mint(to, amount); }
}

contract ItemVaultTest is Test {
    ItemVault public vault;
    MockToken public token;

    address public owner = address(this);
    address public alice = makeAddr("alice");
    address public bob   = makeAddr("bob");

    function setUp() public {
        token = new MockToken();
        vault = new ItemVault(IERC20(address(token)));
        token.mint(alice, 1000e18);
        token.mint(bob,   1000e18);
        token.mint(owner, 10000e18);
    }

    function test_Deposit() public {
        vm.startPrank(alice);
        token.approve(address(vault), 100e18);
        vault.deposit(100e18, alice);
        vm.stopPrank();
        assertEq(vault.balanceOf(alice), 100e18);
    }

    function test_Withdraw() public {
        vm.startPrank(alice);
        token.approve(address(vault), 100e18);
        vault.deposit(100e18, alice);
        vault.withdraw(100e18, alice, alice);
        vm.stopPrank();
        assertEq(vault.balanceOf(alice), 0);
        assertEq(token.balanceOf(alice), 1000e18);
    }

    function test_Redeem() public {
        vm.startPrank(alice);
        token.approve(address(vault), 100e18);
        vault.deposit(100e18, alice);
        uint256 shares = vault.balanceOf(alice);
        vault.redeem(shares, alice, alice);
        vm.stopPrank();
        assertApproxEqAbs(token.balanceOf(alice), 1000e18, 1);
    }

    function test_SharePriceAfterHarvest() public {
        vm.startPrank(alice);
        token.approve(address(vault), 100e18);
        vault.deposit(100e18, alice);
        vm.stopPrank();

        uint256 before = vault.convertToAssets(1e18);
        token.approve(address(vault), 50e18);
        vault.harvest(50e18);
        uint256 afterHarvest = vault.convertToAssets(1e18);

        assertGt(afterHarvest, before);
    }

    function test_MultipleDepositors() public {
        vm.startPrank(alice);
        token.approve(address(vault), 100e18);
        vault.deposit(100e18, alice);
        vm.stopPrank();

        vm.startPrank(bob);
        token.approve(address(vault), 100e18);
        vault.deposit(100e18, bob);
        vm.stopPrank();

        assertEq(vault.balanceOf(alice), vault.balanceOf(bob));
    }

    function test_WithdrawMoreAfterHarvest() public {
        vm.startPrank(alice);
        token.approve(address(vault), 100e18);
        vault.deposit(100e18, alice);
        vm.stopPrank();

        token.approve(address(vault), 100e18);
        vault.harvest(100e18);

        uint256 shares = vault.balanceOf(alice);
        vm.startPrank(alice);
        vault.redeem(shares, alice, alice);
        vm.stopPrank();

        assertGt(token.balanceOf(alice), 1000e18);
    }

    function test_ConvertToShares() public {
        vm.startPrank(alice);
        token.approve(address(vault), 100e18);
        vault.deposit(100e18, alice);
        vm.stopPrank();

        uint256 shares = vault.convertToShares(100e18);
        uint256 assets = vault.convertToAssets(shares);
        assertApproxEqAbs(assets, 100e18, 1);
    }

    function test_OnlyOwnerCanHarvest() public {
        vm.expectRevert();
        vm.prank(alice);
        vault.harvest(100e18);
    }

    function test_FuzzDeposit(uint256 amount) public {
        amount = bound(amount, 1e15, 500e18);
        token.mint(alice, amount);
        vm.startPrank(alice);
        token.approve(address(vault), amount);
        vault.deposit(amount, alice);
        vm.stopPrank();
        assertGt(vault.balanceOf(alice), 0);
    }
}