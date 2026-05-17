// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/GameToken.sol";
import "../src/MyGovernor.sol";
import "../src/MyTimelock.sol";
import "../src/GameItems.sol";

contract GovernorTest is Test {
    GameToken public token;
    MyGovernor public governor;
    MyTimelock public timelock;
    GameItems public items;

    address public deployer = address(this);
    address public voter1 = makeAddr("voter1");
    address public voter2 = makeAddr("voter2");
    address public voter3 = makeAddr("voter3");

    bytes32 constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    function setUp() public {
        token = new GameToken(deployer);

        address[] memory empty = new address[](0);
        timelock = new MyTimelock(0, empty, empty, deployer);

        governor = new MyGovernor(IVotes(address(token)), timelock);

        timelock.grantRole(PROPOSER_ROLE, address(governor));
        timelock.grantRole(EXECUTOR_ROLE, address(0));

        items = new GameItems();

        token.transfer(voter1, 300_000e18);
        token.transfer(voter2, 200_000e18);
        token.transfer(voter3, 100_000e18);

        vm.prank(voter1);
        token.delegate(voter1);
        vm.prank(voter2);
        token.delegate(voter2);
        vm.prank(voter3);
        token.delegate(voter3);
        token.delegate(deployer);

        vm.roll(block.number + 1);
    }

    function _propose() internal returns (uint256) {
        bytes memory calldata_ = abi.encodeWithSignature("grantRole(bytes32,address)", items.MINTER_ROLE(), voter1);
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(items);
        calldatas[0] = calldata_;

        vm.prank(voter1);
        return governor.propose(targets, values, calldatas, "Grant minter role");
    }

    function test_GovernorName() public view {
        assertEq(governor.name(), "GameFi Governor");
    }

    function test_VotingDelay() public view {
        assertEq(governor.votingDelay(), 7200);
    }

    function test_VotingPeriod() public view {
        assertEq(governor.votingPeriod(), 50400);
    }

    function test_ProposalThreshold() public view {
        assertEq(governor.proposalThreshold(), 10000e18);
    }

    function test_Quorum() public view {
        uint256 q = governor.quorum(block.number - 1);
        assertGt(q, 0);
    }

    function test_TokenTotalSupply() public view {
        assertEq(token.totalSupply(), 1_000_000e18);
    }

    function test_TokenDistribution() public view {
        assertEq(token.balanceOf(voter1), 300_000e18);
        assertEq(token.balanceOf(voter2), 200_000e18);
        assertEq(token.balanceOf(voter3), 100_000e18);
    }

    function test_DelegationWorks() public view {
        assertGt(token.getVotes(voter1), 0);
        assertGt(token.getVotes(voter2), 0);
    }

    function test_CreateProposal() public {
        uint256 proposalId = _propose();
        assertGt(proposalId, 0);
    }

    function test_ProposalStateIsPending() public {
        uint256 proposalId = _propose();
        assertEq(uint256(governor.state(proposalId)), 0);
    }

    function test_ProposalStateIsActiveAfterDelay() public {
        uint256 proposalId = _propose();
        vm.roll(block.number + 7201);
        assertEq(uint256(governor.state(proposalId)), 1);
    }

    function test_CastVoteFor() public {
        uint256 proposalId = _propose();
        vm.roll(block.number + 7201);
        vm.prank(voter1);
        governor.castVote(proposalId, 1);
        (uint256 against, uint256 forVotes, uint256 abstain) = governor.proposalVotes(proposalId);
        assertGt(forVotes, 0);
        assertEq(against, 0);
        assertEq(abstain, 0);
    }

    function test_CastVoteAgainst() public {
        uint256 proposalId = _propose();
        vm.roll(block.number + 7201);
        vm.prank(voter1);
        governor.castVote(proposalId, 0);
        (uint256 against,,) = governor.proposalVotes(proposalId);
        assertGt(against, 0);
    }

    function test_CastVoteAbstain() public {
        uint256 proposalId = _propose();
        vm.roll(block.number + 7201);
        vm.prank(voter1);
        governor.castVote(proposalId, 2);
        (,, uint256 abstain) = governor.proposalVotes(proposalId);
        assertGt(abstain, 0);
    }

    function test_CannotVoteTwice() public {
        uint256 proposalId = _propose();
        vm.roll(block.number + 7201);
        vm.prank(voter1);
        governor.castVote(proposalId, 1);
        vm.expectRevert();
        vm.prank(voter1);
        governor.castVote(proposalId, 1);
    }

    function test_ProposalDefeatedIfQuorumNotMet() public {
        address smallVoter = makeAddr("smallVoter");
        token.transfer(smallVoter, 100e18);
        vm.prank(smallVoter);
        token.delegate(smallVoter);
        vm.roll(block.number + 1);

        bytes[] memory calldatas = new bytes[](1);
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        targets[0] = address(items);
        calldatas[0] = abi.encodeWithSignature("grantRole(bytes32,address)", items.MINTER_ROLE(), smallVoter);

        vm.prank(voter1);
        uint256 pid = governor.propose(targets, values, calldatas, "Small proposal");
        vm.roll(block.number + 7201);
        vm.prank(smallVoter);
        governor.castVote(pid, 1);
        vm.roll(block.number + 50401);
        assertEq(uint256(governor.state(pid)), 3);
    }

    function test_FullLifecycle() public {
        items.grantRole(items.DEFAULT_ADMIN_ROLE(), address(timelock));

        bytes memory calldata_ = abi.encodeWithSignature("grantRole(bytes32,address)", items.MINTER_ROLE(), voter1);
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(items);
        calldatas[0] = calldata_;

        vm.prank(voter1);
        uint256 pid = governor.propose(targets, values, calldatas, "Full lifecycle");

        vm.roll(block.number + 7201);
        vm.prank(voter1);
        governor.castVote(pid, 1);
        vm.prank(voter2);
        governor.castVote(pid, 1);
        vm.roll(block.number + 50401);
        assertEq(uint256(governor.state(pid)), 4);

        bytes32 descHash = keccak256(bytes("Full lifecycle"));
        governor.queue(targets, values, calldatas, descHash);

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 1);

        uint8 stateAfterQueue = uint8(governor.state(pid));
        assertTrue(stateAfterQueue == 5 || stateAfterQueue == 7, "Should be Queued or Executed");

        if (stateAfterQueue == 5) {
            governor.execute(targets, values, calldatas, descHash);
            assertEq(uint256(governor.state(pid)), 7);
        }
    }

    function test_DelegateeVotesOnBehalf() public {
        vm.prank(voter3);
        token.delegate(voter1);
        vm.roll(block.number + 1);

        uint256 power = token.getVotes(voter1);
        assertGt(power, 300_000e18);
    }

    function test_TimelockDelay() public view {
        assertEq(timelock.getMinDelay(), 0);
    }

    function test_GovernorIsProposer() public view {
        assertTrue(timelock.hasRole(PROPOSER_ROLE, address(governor)));
    }

    function test_AnyoneCanExecute() public view {
        assertTrue(timelock.hasRole(EXECUTOR_ROLE, address(0)));
    }
}
