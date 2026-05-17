// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/ResourceAMM.sol";
import "../src/ItemVault.sol";
import "../src/GameItems.sol";
import "../src/YulMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor() ERC20("Mock", "MCK") {}
    function mint(address to, uint256 amount) external { _mint(to, amount); }
}

contract FuzzTest is Test {
    ResourceAMM public amm;
    ItemVault public vault;
    GameItems public items;
    YulMath public yulMath;
    MockToken public tokenA;
    MockToken public tokenB;
    MockToken public vaultToken;

    address public alice = makeAddr("alice");

    function setUp() public {
        tokenA = new MockToken();
        tokenB = new MockToken();
        amm = new ResourceAMM(address(tokenA), address(tokenB));
        vaultToken = new MockToken();
        vault = new ItemVault(IERC20(address(vaultToken)));
        items = new GameItems();
        yulMath = new YulMath();

        tokenA.mint(alice, 100000e18);
        tokenB.mint(alice, 100000e18);
        vm.startPrank(alice);
        tokenA.approve(address(amm), 10000e18);
        tokenB.approve(address(amm), 10000e18);
        amm.addLiquidity(1000e18, 1000e18);
        vm.stopPrank();
    }

    function testFuzz_SwapAmountOut(uint256 amountIn) public {
        amountIn = bound(amountIn, 1e15, 100e18);
        tokenA.mint(alice, amountIn);
        vm.startPrank(alice);
        tokenA.approve(address(amm), amountIn);
        uint256 out = amm.swap(address(tokenA), amountIn, 0);
        vm.stopPrank();
        assertGt(out, 0);
        assertLt(out, amountIn * 2);
    }

    function testFuzz_SwapKInvariant(uint256 amountIn) public {
        amountIn = bound(amountIn, 1e15, 50e18);
        uint256 kBefore = amm.reserve0() * amm.reserve1();
        tokenA.mint(alice, amountIn);
        vm.startPrank(alice);
        tokenA.approve(address(amm), amountIn);
        amm.swap(address(tokenA), amountIn, 0);
        vm.stopPrank();
        assertGe(amm.reserve0() * amm.reserve1(), kBefore);
    }

    function testFuzz_VaultDeposit(uint256 amount) public {
        amount = bound(amount, 1e15, 1000e18);
        vaultToken.mint(alice, amount);
        vm.startPrank(alice);
        vaultToken.approve(address(vault), amount);
        uint256 shares = vault.deposit(amount, alice);
        vm.stopPrank();
        assertGt(shares, 0);
        assertEq(vault.totalAssets(), amount);
    }

    function testFuzz_VaultWithdraw(uint256 amount) public {
        amount = bound(amount, 1e15, 1000e18);
        vaultToken.mint(alice, amount);
        vm.startPrank(alice);
        vaultToken.approve(address(vault), amount);
        vault.deposit(amount, alice);
        vault.withdraw(amount, alice, alice);
        vm.stopPrank();
        assertEq(vault.balanceOf(alice), 0);
        assertApproxEqAbs(vaultToken.balanceOf(alice), amount, 1);
    }

    function testFuzz_VaultSharePrice(uint256 depositAmount, uint256 harvestAmount) public {
        depositAmount = bound(depositAmount, 1e18, 500e18);
        harvestAmount = bound(harvestAmount, 1e18, 100e18);
        vaultToken.mint(alice, depositAmount);
        vm.startPrank(alice);
        vaultToken.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, alice);
        vm.stopPrank();
        uint256 priceBefore = vault.convertToAssets(1e18);
        vaultToken.mint(address(this), harvestAmount);
        vaultToken.approve(address(vault), harvestAmount);
        vault.harvest(harvestAmount);
        uint256 priceAfter = vault.convertToAssets(1e18);
        assertGe(priceAfter, priceBefore);
    }

    function testFuzz_YulSqrt(uint256 x) public view {
        x = bound(x, 0, type(uint128).max);
        uint256 result = yulMath.sqrt(x);
        assertLe(result * result, x);
        if (result > 0) assertGt((result + 1) * (result + 1), x);
    }

    function testFuzz_YulMin(uint256 a, uint256 b) public view {
        uint256 result = yulMath.min(a, b);
        assertLe(result, a);
        assertLe(result, b);
        assertTrue(result == a || result == b);
    }

    function testFuzz_YulMax(uint256 a, uint256 b) public view {
        uint256 result = yulMath.max(a, b);
        assertGe(result, a);
        assertGe(result, b);
        assertTrue(result == a || result == b);
    }

    function testFuzz_AMMAddLiquidity(uint256 amount0, uint256 amount1) public {
        amount0 = bound(amount0, 1e18, 1000e18);
        amount1 = bound(amount1, 1e18, 1000e18);
        tokenA.mint(alice, amount0);
        tokenB.mint(alice, amount1);
        vm.startPrank(alice);
        tokenA.approve(address(amm), amount0);
        tokenB.approve(address(amm), amount1);
        uint256 lp = amm.addLiquidity(amount0, amount1);
        vm.stopPrank();
        assertGt(lp, 0);
    }

    function testFuzz_AMMGetAmountOut(uint256 amountIn) public view {
        amountIn = bound(amountIn, 1e15, 100e18);
        uint256 out = amm.getAmountOut(address(tokenA), amountIn);
        assertGt(out, 0);
        assertLt(out, amm.reserve1());
    }

    function testFuzz_GameItemsMint(uint256 amount) public {
        amount = bound(amount, 1, 50);
        items.mint(alice, 1, amount);
        assertEq(items.balanceOf(alice, 1), amount);
    }
}