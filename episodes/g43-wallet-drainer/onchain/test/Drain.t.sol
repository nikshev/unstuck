// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {LabToken, Collector} from "../src/Lab.sol";

/// ⚠️ An earlier version of this test asserted `vm.getNonce(victim) == 0` to prove "the victim never
/// sent a transaction". That assertion PASSED — vacuously. `vm.prank` changes msg.sender but does not
/// bump a nonce, so the value was 0 in both the permit case and the approve case and the test proved
/// nothing. It is replaced below by assertions on ON-CHAIN STATE, which is the real difference:
/// `approve()` writes an allowance that can be seen and revoked; a permit signature writes nothing.
contract DrainTest is Test {
    LabToken token;
    Collector collector;

    uint256 victimPk = 0xA11CE;
    address victim;
    address attacker = address(0xBAD);

    function setUp() public {
        victim = vm.addr(victimPk);
        token = new LabToken();
        token.mint(victim, 10_000e18);
        vm.prank(attacker);
        collector = new Collector();
    }

    /// The whole episode, as an executable claim.
    function test_PermitSignature_DrainsWithoutTheVictimEverSendingATransaction() public {
        console.log("victim balance at the start  :", token.balanceOf(victim) / 1e18, "LUSD");

        // ---- the victim signs. OFF-CHAIN. No transaction, no gas, nothing broadcast. ----
        uint256 value = type(uint256).max;          // "unlimited"
        uint256 deadline = type(uint256).max;       // "never expires"
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01", token.DOMAIN_SEPARATOR(),
            keccak256(abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                victim, address(collector), value, token.nonces(victim), deadline))));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(victimPk, digest);

        console.log("");
        console.log("--- the victim has now signed the message ---");
        console.log("allowance on-chain           :", token.allowance(victim, address(collector)));
        console.log("token nonce for victim       :", token.nonces(victim));
        console.log("victim balance               :", token.balanceOf(victim) / 1e18, "LUSD");

        // THE CLAIM: signing created NO on-chain state. There is nothing for the victim to see,
        // nothing for a wallet UI to list, and nothing a revoke tool could find — because an
        // allowance was never written. This is what victims describe as "the site did nothing".
        assertEq(token.allowance(victim, address(collector)), 0, "signing granted nothing on-chain");
        assertEq(token.nonces(victim), 0, "the permit nonce has not been consumed yet");
        assertEq(token.balanceOf(victim), 10_000e18, "balance untouched");

        // ---- eleven days later, at a moment of the attacker's choosing ----
        vm.warp(block.timestamp + 11 days);
        vm.prank(attacker);
        collector.redeemAndSweep(address(token), victim, value, deadline, v, r, s);

        console.log("");
        console.log("--- 11 days later, the attacker redeems the signature ---");
        console.log("victim balance               :", token.balanceOf(victim) / 1e18, "LUSD");
        console.log("attacker balance             :", token.balanceOf(attacker) / 1e18, "LUSD");
        console.log("token nonce for victim       :", token.nonces(victim), "<- consumed, by the ATTACKER's tx");

        assertEq(token.balanceOf(victim), 0, "victim drained");
        assertEq(token.balanceOf(attacker), 10_000e18, "attacker holds it");
        assertEq(token.nonces(victim), 1, "the permit was redeemed inside the attacker's transaction");
    }

    /// The other path, for comparison: an ordinary on-chain approval. This one IS visible.
    function test_OnChainApproval_IsAtLeastVisible() public {
        vm.prank(victim);
        token.approve(address(collector), type(uint256).max);

        console.log("");
        console.log("--- the on-chain approval path ---");
        console.log("allowance on-chain           :", token.allowance(victim, address(collector)) == type(uint256).max
            ? "unlimited (max uint256)" : "set");

        // The real, checkable difference: approve() WRITES STATE. It costs gas, it emits an
        // Approval event, a wallet can list it, and the victim can revoke it by setting it to 0.
        // A permit signature does none of that until the moment it is spent.
        assertGt(token.allowance(victim, address(collector)), 0, "approve() is visible on-chain");

        vm.prank(victim);
        token.approve(address(collector), 0);
        assertEq(token.allowance(victim, address(collector)), 0, "and it can be revoked");
        console.log("revoked by the victim        : yes - because there was something to revoke");

        vm.prank(victim);
        token.approve(address(collector), type(uint256).max);

        vm.prank(attacker);
        collector.sweepAllowance(address(token), victim);
        assertEq(token.balanceOf(attacker), 10_000e18);
    }
}
