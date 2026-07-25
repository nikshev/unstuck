// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Wallet.sol";
import "../src/SafeWallet.sol";
import "../src/Attack.sol";

contract PhishTest is Test {
    address owner    = makeAddr("owner");
    address attacker = makeAddr("attacker");

    function setUp() public { vm.deal(owner, 100 ether); }

    function _log(string memory tag, Wallet w) internal view {
        console.log(tag);
        console.log("   wallet balance  :", address(w).balance);
        console.log("   attacker balance:", attacker.balance);
    }

    // ACT 1 — HONEST: the owner spends their own wallet directly.
    function test_1_honest_ownerSpends() public {
        vm.prank(owner, owner);
        Wallet w = new Wallet{value: 10 ether}();
        address payable dest = payable(makeAddr("friend"));

        vm.prank(owner, owner);                 // msg.sender = tx.origin = owner
        w.transferTo(dest, 3 ether);
        console.log("HONEST: owner sent 3 ETH to a friend");
        console.log("   wallet balance:", address(w).balance);
        console.log("   friend balance:", dest.balance);
        assertEq(address(w).balance, 7 ether);
        assertEq(dest.balance, 3 ether);
    }

    // ACT 2 — ATTACK: owner is phished into calling Attack; tx.origin is still
    // the owner, so the vulnerable wallet obeys and drains to the attacker.
    function test_2_attack_drains() public {
        vm.prank(owner, owner);
        Wallet w = new Wallet{value: 10 ether}();
        Attack a = new Attack(address(w), payable(attacker));

        _log("BEFORE", w);
        vm.prank(owner, owner);                 // the human owner clicks the phishing link
        a.claimAirdrop();                       // msg.sender=Attack, but tx.origin=owner
        _log("AFTER (drained)", w);

        assertEq(address(w).balance, 0);
        assertEq(attacker.balance, 10 ether);   // whole wallet stolen
    }

    // ACT 3 — FIX: msg.sender auth. Same phish now reverts (Attack != owner).
    function test_3_fixed_reverts() public {
        vm.prank(owner, owner);
        SafeWallet w = new SafeWallet{value: 10 ether}();
        Attack a = new Attack(address(w), payable(attacker));

        vm.prank(owner, owner);
        vm.expectRevert(bytes("not owner"));
        a.claimAirdrop();                       // msg.sender=Attack != owner -> revert
        console.log("FIXED: phish reverted, wallet intact:", address(w).balance);
        assertEq(address(w).balance, 10 ether);
    }
}
