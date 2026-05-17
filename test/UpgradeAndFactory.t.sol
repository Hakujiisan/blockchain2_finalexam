// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/GameItemsV1.sol";
import "../src/GameItemsV2.sol";
import "../src/GameFactory.sol";
import "../src/YulMath.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract UpgradeAndFactoryTest is Test {
    GameItemsV1 public implV1;
    GameItemsV2 public implV2;
    GameItemsV1 public proxy;
    GameFactory public factory;
    YulMath public yulMath;

    address public admin = address(this);
    address public player = makeAddr("player");

    function setUp() public {
        implV1 = new GameItemsV1();
        bytes memory initData = abi.encodeWithSelector(
            GameItemsV1.initialize.selector, admin
        );
        ERC1967Proxy proxyContract = new ERC1967Proxy(address(implV1), initData);
        proxy = GameItemsV1(address(proxyContract));

        implV2 = new GameItemsV2();
        factory = new GameFactory();
        yulMath = new YulMath();
    }

    function test_ProxyInitialized() public view {
        assertEq(proxy.version(), "V1");
    }

    function test_ProxyMint() public {
        proxy.mint(player, 1, 100);
        assertEq(proxy.balanceOf(player, 1), 100);
    }

    function test_UpgradeToV2() public {
        proxy.upgradeToAndCall(address(implV2), "");
        GameItemsV2 proxyV2 = GameItemsV2(address(proxy));
        assertEq(proxyV2.version(), "V2");
    }

    function test_V2NewFunctionality() public {
        proxy.upgradeToAndCall(address(implV2), "");
        GameItemsV2 proxyV2 = GameItemsV2(address(proxy));
        proxyV2.setDropRate(50);
        assertEq(proxyV2.dropRate(), 50);
    }

    function test_StatePreservedAfterUpgrade() public {
        proxy.mint(player, 1, 100);
        proxy.upgradeToAndCall(address(implV2), "");
        assertEq(proxy.balanceOf(player, 1), 100);
    }

    function test_OnlyUpgraderCanUpgrade() public {
        vm.expectRevert();
        vm.prank(player);
        proxy.upgradeToAndCall(address(implV2), "");
    }

    function test_FactoryDeployItems() public {
        address items = factory.deployItems();
        assertFalse(items == address(0));
        assertEq(factory.getDeployedItems().length, 1);
    }

    function test_FactoryDeployMultiple() public {
        factory.deployItems();
        factory.deployItems();
        assertEq(factory.getDeployedItems().length, 2);
    }

    function test_FactoryDeterministicDeploy() public {
        bytes32 salt = keccak256("test-salt");
        address predicted = factory.predictAddress(salt);
        address deployed = factory.deployItemsDeterministic(salt);
        assertEq(predicted, deployed);
    }

    function test_FactoryDeployVault() public {
        address mockToken = makeAddr("token");
        vm.etch(mockToken, hex"00");
        address vault = factory.deployVault(mockToken);
        assertFalse(vault == address(0));
        assertEq(factory.getDeployedVaults().length, 1);
    }

    function test_YulSqrt() public view {
        assertEq(yulMath.sqrt(0), 0);
        assertEq(yulMath.sqrt(1), 1);
        assertEq(yulMath.sqrt(4), 2);
        assertEq(yulMath.sqrt(9), 3);
        assertEq(yulMath.sqrt(16), 4);
        assertEq(yulMath.sqrt(100), 10);
    }

    function test_YulMin() public view {
        assertEq(yulMath.min(5, 3), 3);
        assertEq(yulMath.min(3, 5), 3);
        assertEq(yulMath.min(5, 5), 5);
    }

    function test_YulMax() public view {
        assertEq(yulMath.max(5, 3), 5);
        assertEq(yulMath.max(3, 5), 5);
        assertEq(yulMath.max(5, 5), 5);
    }

    function test_YulMulDiv() public view {
        assertEq(yulMath.mulDiv(100, 3, 10), 30);
        assertEq(yulMath.mulDiv(1000, 1, 4), 250);
    }

    function test_FuzzYulSqrt(uint256 x) public view {
        x = bound(x, 0, 1e30);
        uint256 result = yulMath.sqrt(x);
        assertLe(result * result, x);
    }
}