// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ArbDemo.sol";

contract ArbDemoTest is Test {
    // The OLD router lets the attacker craft an arbitrary call that pulls the
    // victim's approved tokens straight to the attacker.
    function test_OLD_ArbitraryCall_DrainsVictim() public {
        Demo_OLD_Vulnerable demo = new Demo_OLD_Vulnerable();
        emit log_named_uint("victim before  ", demo.victimBalance());
        assertEq(demo.victimBalance(), 1_000_000, "victim starts with 1,000,000");
        demo.attack();
        emit log_named_uint("victim after   ", demo.victimBalance());
        emit log_named_uint("attacker after ", demo.attackerBalance());
        assertEq(demo.victimBalance(), 0, "victim fully drained");
        assertEq(demo.attackerBalance(), 1_000_000, "attacker took everything");
    }

    // The FIXED router only calls whitelisted targets, so the same attack reverts.
    function test_FIXED_ArbitraryCall_Reverts() public {
        Demo_NEW_Fixed demo = new Demo_NEW_Fixed();
        emit log_named_uint("victim before  ", demo.victimBalance());
        vm.expectRevert(bytes("target not allowed"));
        demo.attack();
        emit log_named_uint("victim after   ", demo.victimBalance());
        assertEq(demo.victimBalance(), 1_000_000, "victim untouched");
    }
}
