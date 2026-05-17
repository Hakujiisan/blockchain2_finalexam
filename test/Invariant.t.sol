// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "forge-std/StdInvariant.sol";
import "../src/ResourceAMM.sol";
import "../src/ItemVault.sol";
import "../src/GameItems.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract AMMHandler is Test {
    ResourceAMM public amm;
    MockToken public token0;
    MockToken public token1;
    address[] public actors;

    constructor(ResourceAMM _amm, MockToken _t0, MockToken _t1) {
        amm = _amm;
        token0 = _t0;
        token1 = _t1;
        actors.push(makeAddr("actor1"));
        actors.push(makeAddr("actor2"));
    }

    function swap(uint256 actorSeed, uint256 amountIn) public {
        amountIn = bound(amountIn, 1e15, 10e18);
        address actor = actors[actorSeed % actors.length];
        token0.mint(actor, amountIn);
        vm.startPrank(actor);
        token0.approve(address(amm), amountIn);
        if (amm.reserve0() > 0 && amm.reserve1() > 0) {
            amm.swap(address(token0), amountIn, 0);
        }
        vm.stopPrank();
    }

    function addLiquidity(uint256 amount0, uint256 amount1) public {
        amount0 = bound(amount0, 1e18, 100e18);
        amount1 = bound(amount1, 1e18, 100e18);
        token0.mint(address(this), amount0);
        token1.mint(address(this), amount1);
        token0.approve(address(amm), amount0);
        token1.approve(address(amm), amount1);
        amm.addLiquidity(amount0, amount1);
    }
}

contract InvariantTest is Test {
    ResourceAMM public amm;
    MockToken public token0;
    MockToken public token1;
    AMMHandler public handler;
    ItemVault public vault;
    MockToken public vaultToken;
    GameItems public items;

    function setUp() public {
        token0 = new MockToken("Token0", "TK0");
        token1 = new MockToken("Token1", "TK1");
        amm = new ResourceAMM(address(token0), address(token1));

        handler = new AMMHandler(amm, token0, token1);

        token0.mint(address(handler), 1000e18);
        token1.mint(address(handler), 1000e18);
        vm.startPrank(address(handler));
        token0.approve(address(amm), 1000e18);
        token1.approve(address(amm), 1000e18);
        amm.addLiquidity(500e18, 500e18);
        vm.stopPrank();

        vaultToken = new MockToken("Vault", "VLT");
        vault = new ItemVault(IERC20(address(vaultToken)));

        items = new GameItems();

        targetContract(address(handler));
    }

    function invariant_KNeverDecreases() public view {
        if (amm.reserve0() > 0 && amm.reserve1() > 0) {
            assertGe(amm.reserve0() * amm.reserve1(), 500e18 * 500e18);
        }
    }

    function invariant_ReservesMatchBalances() public view {
        assertEq(token0.balanceOf(address(amm)), amm.reserve0());
        assertEq(token1.balanceOf(address(amm)), amm.reserve1());
    }

    function invariant_VaultSharesNeverExceedDeposits() public view {
        uint256 totalAssets = vault.totalAssets();
        uint256 totalSupply = vault.totalSupply();
        if (totalSupply > 0) {
            assertGe(totalAssets, totalSupply);
        }
    }

    function invariant_GameItemsMaxSupply() public view {
        assertLe(items.totalMinted(1000), items.maxSupply(1000));
        assertLe(items.totalMinted(1001), items.maxSupply(1001));
        assertLe(items.totalMinted(1002), items.maxSupply(1002));
    }

    function invariant_AMMPositiveReserves() public view {
        assertGt(amm.reserve0(), 0);
        assertGt(amm.reserve1(), 0);
    }
}
