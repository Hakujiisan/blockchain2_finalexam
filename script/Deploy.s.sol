// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/GameToken.sol";
import "../src/GameItems.sol";
import "../src/ResourceAMM.sol";
import "../src/ItemVault.sol";
import "../src/MockVRF.sol";
import "../src/MockAggregator.sol";
import "../src/MyTimelock.sol";
import "../src/MyGovernor.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        GameToken token = new GameToken(deployer);
        console.log("GameToken:", address(token));

        GameItems items = new GameItems();
        console.log("GameItems:", address(items));

        ResourceAMM amm = new ResourceAMM(address(token), address(token));
        console.log("ResourceAMM:", address(amm));

        ItemVault vault = new ItemVault(IERC20(address(token)));
        console.log("ItemVault:", address(vault));

        LootBox lootbox = new LootBox(address(items));
        console.log("LootBox:", address(lootbox));

        MockAggregator oracle = new MockAggregator(2000e8);
        console.log("MockAggregator:", address(oracle));

        address[] memory empty = new address[](0);
        MyTimelock timelock = new MyTimelock(172800, empty, empty, deployer);
        console.log("MyTimelock:", address(timelock));

        MyGovernor governor = new MyGovernor(IVotes(address(token)), timelock);
        console.log("MyGovernor:", address(governor));

        bytes32 PROPOSER = timelock.PROPOSER_ROLE();
        bytes32 EXECUTOR = timelock.EXECUTOR_ROLE();
        timelock.grantRole(PROPOSER, address(governor));
        timelock.grantRole(EXECUTOR, address(0));

        items.grantRole(items.MINTER_ROLE(), address(lootbox));

        vm.stopBroadcast();
        console.log("Deploy complete!");
    }
}
