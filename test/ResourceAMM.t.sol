// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/ResourceAMM.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract ResourceAMMTest is Test {
    ResourceAMM public amm;
    MockERC20 public tokenA;
    MockERC20 public tokenB;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    function setUp() public {
        tokenA = new MockERC20("Gold Token", "GOLD");
        tokenB = new MockERC20("Wood Token", "WOOD");
        amm = new ResourceAMM(address(tokenA), address(tokenB));

        tokenA.mint(alice, 10000e18);
        tokenB.mint(alice, 10000e18);
        tokenA.mint(bob, 1000e18);
        tokenB.mint(bob, 1000e18);
    }

    function test_AddLiquidity() public {
        vm.startPrank(alice);
        tokenA.approve(address(amm), 1000e18);
        tokenB.approve(address(amm), 1000e18);
        uint256 lp = amm.addLiquidity(1000e18, 1000e18);
        vm.stopPrank();

        assertGt(lp, 0);
        assertEq(amm.reserve0(), 1000e18);
        assertEq(amm.reserve1(), 1000e18);
    }

    function test_RemoveLiquidity() public {
        vm.startPrank(alice);
        tokenA.approve(address(amm), 1000e18);
        tokenB.approve(address(amm), 1000e18);
        uint256 lp = amm.addLiquidity(1000e18, 1000e18);
        amm.lpToken().approve(address(amm), lp);
        (uint256 a, uint256 b) = amm.removeLiquidity(lp);
        vm.stopPrank();

        assertGt(a, 0);
        assertGt(b, 0);
        assertEq(amm.reserve0(), 0);
        assertEq(amm.reserve1(), 0);
    }

    function test_Swap() public {
        vm.startPrank(alice);
        tokenA.approve(address(amm), 1000e18);
        tokenB.approve(address(amm), 1000e18);
        amm.addLiquidity(1000e18, 1000e18);
        vm.stopPrank();

        vm.startPrank(bob);
        tokenA.approve(address(amm), 100e18);
        uint256 out = amm.swap(address(tokenA), 100e18, 0);
        vm.stopPrank();

        assertGt(out, 0);
        assertLt(out, 100e18);
    }

    function test_SwapFee() public {
        vm.startPrank(alice);
        tokenA.approve(address(amm), 1000e18);
        tokenB.approve(address(amm), 1000e18);
        amm.addLiquidity(1000e18, 1000e18);
        vm.stopPrank();

        uint256 amountOut = amm.getAmountOut(address(tokenA), 100e18);
        assertLt(amountOut, 100e18);
    }

    function test_SlippageProtection() public {
        vm.startPrank(alice);
        tokenA.approve(address(amm), 1000e18);
        tokenB.approve(address(amm), 1000e18);
        amm.addLiquidity(1000e18, 1000e18);
        vm.stopPrank();

        vm.startPrank(bob);
        tokenA.approve(address(amm), 100e18);
        vm.expectRevert("Slippage exceeded");
        amm.swap(address(tokenA), 100e18, 999e18);
        vm.stopPrank();
    }

    function test_InvalidToken() public {
        vm.expectRevert("Invalid token");
        amm.swap(address(0x123), 100e18, 0);
    }

    function test_KInvariant() public {
        vm.startPrank(alice);
        tokenA.approve(address(amm), 1000e18);
        tokenB.approve(address(amm), 1000e18);
        amm.addLiquidity(1000e18, 1000e18);
        vm.stopPrank();

        uint256 kBefore = amm.reserve0() * amm.reserve1();

        vm.startPrank(bob);
        tokenA.approve(address(amm), 100e18);
        amm.swap(address(tokenA), 100e18, 0);
        vm.stopPrank();

        uint256 kAfter = amm.reserve0() * amm.reserve1();
        assertGe(kAfter, kBefore);
    }

    function test_GetAmountOut() public {
        vm.startPrank(alice);
        tokenA.approve(address(amm), 1000e18);
        tokenB.approve(address(amm), 1000e18);
        amm.addLiquidity(1000e18, 1000e18);
        vm.stopPrank();

        uint256 out = amm.getAmountOut(address(tokenA), 100e18);
        assertGt(out, 0);
    }

    function test_FuzzSwap(uint256 amountIn) public {
        amountIn = bound(amountIn, 1e15, 100e18);

        vm.startPrank(alice);
        tokenA.approve(address(amm), 1000e18);
        tokenB.approve(address(amm), 1000e18);
        amm.addLiquidity(1000e18, 1000e18);
        vm.stopPrank();

        tokenA.mint(bob, amountIn);
        vm.startPrank(bob);
        tokenA.approve(address(amm), amountIn);
        uint256 out = amm.swap(address(tokenA), amountIn, 0);
        vm.stopPrank();

        assertGt(out, 0);
        assertGe(amm.reserve0() * amm.reserve1(), 1000e18 * 1000e18);
    }
}
