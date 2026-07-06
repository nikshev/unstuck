// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ReentrancyDemo.sol";

contract ReentrancyDemoTest is Test {
    function setUp() public { vm.deal(address(this), 200 ether); }

    function test_OLD_Reentrancy_DrainsVault() public {
        // 1. Deploy the attacker; its constructor makes a vulnerable vault and seeds it
        //    with 3 ether standing in for OTHER users' deposits.
        Attacker_OLD atk = new Attacker_OLD{value: 3 ether}();
        emit log_named_uint("pool after seed (others)  ", atk.poolBalance());
        assertEq(atk.poolBalance(), 3, "vault holds 3 (other users' funds)");

        // 2. The attacker deposits just 1 ether of their own.
        atk.attackerDeposit{value: 1 ether}();
        emit log_named_uint("pool after attacker deposit", atk.poolBalance());
        assertEq(atk.poolBalance(), 4, "pool is now 3 + 1");

        // 3. steal() -> vault.withdraw() -> the attacker's receive() re-enters withdraw()
        //    before the balance is zeroed -> the vault pays again and again until it's empty.
        atk.steal();
        emit log_named_uint("pool after steal          ", atk.poolBalance());
        emit log_named_uint("attacker loot             ", atk.myLoot());
        assertEq(atk.poolBalance(), 0, "vault fully drained");
        assertEq(atk.myLoot(), 4, "attacker took everything for a 1 ETH deposit");
    }

    function test_FIXED_Reentrancy_Reverts() public {
        Attacker_NEW atk = new Attacker_NEW{value: 3 ether}();
        atk.attackerDeposit{value: 1 ether}();
        emit log_named_uint("pool before steal", atk.poolBalance());
        assertEq(atk.poolBalance(), 4);
        // The fixed vault zeroes the balance first, so the re-entrant withdraw reverts.
        vm.expectRevert();
        atk.steal();
        emit log_named_uint("pool after (untouched)", atk.poolBalance());
        assertEq(atk.poolBalance(), 4, "vault untouched");
    }
}
