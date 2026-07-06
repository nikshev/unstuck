// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ReentrancyDemo.sol";

contract ReentrancyDemoTest is Test {
    function setUp() public { vm.deal(address(this), 200 ether); }

    // The OLD vault sends ETH before zeroing the balance, so the attacker's
    // receive() re-enters withdraw() and drains everyone's funds.
    function test_OLD_Reentrancy_DrainsVault() public {
        Demo_OLD_Vulnerable demo = new Demo_OLD_Vulnerable{value: 4 ether}();
        emit log_named_uint("vault before  ", demo.vaultBalance());
        assertEq(demo.vaultBalance(), 3, "vault holds 10 (other users' funds)");
        demo.attack();
        emit log_named_uint("vault after   ", demo.vaultBalance());
        emit log_named_uint("attacker loot ", demo.attackerLoot());
        assertEq(demo.vaultBalance(), 0, "vault fully drained");
        assertEq(demo.attackerLoot(), 4, "attacker took everything for a 1 ETH deposit");
    }

    // The FIXED vault zeroes the balance first, so the re-entrant withdraw reverts.
    function test_FIXED_Reentrancy_Reverts() public {
        Demo_NEW_Fixed demo = new Demo_NEW_Fixed{value: 4 ether}();
        emit log_named_uint("vault before  ", demo.vaultBalance());
        vm.expectRevert();
        demo.attack();
        emit log_named_uint("vault after   ", demo.vaultBalance());
        assertEq(demo.vaultBalance(), 3, "vault untouched");
    }
}
