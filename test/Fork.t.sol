// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/MockAggregator.sol";
import "../src/ItemVault.sol";
import "../src/ResourceAMM.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}
    function mint(address to, uint256 amount) external { _mint(to, amount); }
}

contract ForkTest is Test {
    MockAggregator public oracle;
    ItemVault public vault;
    MockToken public token;
    ResourceAMM public amm;

    address public alice = makeAddr("alice");
    address public bob   = makeAddr("bob");

    function setUp() public {
        oracle = new MockAggregator(2000e8);
        token  = new MockToken("Test", "TST");
        vault  = new ItemVault(IERC20(address(token)));
        amm    = new ResourceAMM(address(token), address(token));

        token.mint(alice, 10000e18);
        token.mint(bob,   10000e18);
    }

    function test_Fork_OraclePrice() public view {
        (, int256 price,,,) = oracle.latestRoundData();
        assertEq(price, 2000e8);
        assertEq(oracle.decimals(), 8);
    }

    function test_Fork_OracleStaleness() public {
        vm.warp(block.timestamp + 3 hours);
        oracle.setUpdatedAt(block.timestamp - 2 hours);
        (, , , uint256 updatedAt,) = oracle.latestRoundData();
        assertTrue(block.timestamp - updatedAt > 1 hours);
    }

    function test_Fork_OraclePriceUpdate() public {
        oracle.setPrice(3000e8);
        (, int256 price,,,) = oracle.latestRoundData();
        assertEq(price, 3000e8);
    }

    function test_Fork_VaultDepositWithdraw() public {
        vm.startPrank(alice);
        token.approve(address(vault), 1000e18);
        vault.deposit(1000e18, alice);
        assertEq(vault.balanceOf(alice), 1000e18);
        vault.withdraw(1000e18, alice, alice);
        assertEq(vault.balanceOf(alice), 0);
        vm.stopPrank();
    }

    function test_Fork_VaultSharePrice() public {
        vm.startPrank(alice);
        token.approve(address(vault), 1000e18);
        vault.deposit(1000e18, alice);
        vm.stopPrank();

        uint256 priceBefore = vault.convertToAssets(1e18);
        token.mint(address(this), 500e18);
        token.approve(address(vault), 500e18);
        vault.harvest(500e18);
        uint256 priceAfter = vault.convertToAssets(1e18);

        assertGt(priceAfter, priceBefore);
    }

    function test_Fork_AMMSwapBothDirections() public {
        MockToken tokenA = new MockToken("A", "A");
        MockToken tokenB = new MockToken("B", "B");
        ResourceAMM testAmm = new ResourceAMM(address(tokenA), address(tokenB));

        tokenA.mint(alice, 2000e18);
        tokenB.mint(alice, 2000e18);

        vm.startPrank(alice);
        tokenA.approve(address(testAmm), 1000e18);
        tokenB.approve(address(testAmm), 1000e18);
        testAmm.addLiquidity(1000e18, 1000e18);

        tokenA.approve(address(testAmm), 100e18);
        uint256 out1 = testAmm.swap(address(tokenA), 100e18, 0);
        assertGt(out1, 0);

        tokenB.approve(address(testAmm), 50e18);
        uint256 out2 = testAmm.swap(address(tokenB), 50e18, 0);
        assertGt(out2, 0);
        vm.stopPrank();
    }

    function test_Fork_MultiUserVault() public {
        vm.startPrank(alice);
        token.approve(address(vault), 500e18);
        vault.deposit(500e18, alice);
        vm.stopPrank();

        vm.startPrank(bob);
        token.approve(address(vault), 500e18);
        vault.deposit(500e18, bob);
        vm.stopPrank();

        assertEq(vault.balanceOf(alice), vault.balanceOf(bob));
        assertEq(vault.totalAssets(), 1000e18);
    }

    function test_Fork_AMMArbitrage() public {
        MockToken tokenA = new MockToken("A", "A");
        MockToken tokenB = new MockToken("B", "B");
        ResourceAMM testAmm = new ResourceAMM(address(tokenA), address(tokenB));

        tokenA.mint(alice, 5000e18);
        tokenB.mint(alice, 5000e18);

        vm.startPrank(alice);
        tokenA.approve(address(testAmm), 1000e18);
        tokenB.approve(address(testAmm), 1000e18);
        testAmm.addLiquidity(1000e18, 1000e18);

        uint256 kBefore = testAmm.reserve0() * testAmm.reserve1();

        tokenA.approve(address(testAmm), 200e18);
        testAmm.swap(address(tokenA), 200e18, 0);

        uint256 kAfter = testAmm.reserve0() * testAmm.reserve1();
        assertGe(kAfter, kBefore);
        vm.stopPrank();
    }

    function test_Fork_VaultZeroDeposit() public view {
        uint256 shares = vault.previewDeposit(0);
        assertEq(shares, 0);
    }

    function test_Fork_AMMRemoveAllLiquidity() public {
        MockToken tokenA = new MockToken("A", "A");
        MockToken tokenB = new MockToken("B", "B");
        ResourceAMM testAmm = new ResourceAMM(address(tokenA), address(tokenB));

        tokenA.mint(alice, 1000e18);
        tokenB.mint(alice, 1000e18);

        vm.startPrank(alice);
        tokenA.approve(address(testAmm), 1000e18);
        tokenB.approve(address(testAmm), 1000e18);
        uint256 lp = testAmm.addLiquidity(1000e18, 1000e18);

        testAmm.lpToken().approve(address(testAmm), lp);
        (uint256 a, uint256 b) = testAmm.removeLiquidity(lp);
        vm.stopPrank();

        assertGt(a, 0);
        assertGt(b, 0);
        assertEq(testAmm.reserve0(), 0);
        assertEq(testAmm.reserve1(), 0);
    }

    function test_Fork_OracleMultipleUpdates() public {
        int256[] memory prices = new int256[](3);
        prices[0] = 1500e8;
        prices[1] = 2500e8;
        prices[2] = 2000e8;

        for (uint256 i = 0; i < prices.length; i++) {
            oracle.setPrice(prices[i]);
            (, int256 price,,,) = oracle.latestRoundData();
            assertEq(price, prices[i]);
        }
    }
}