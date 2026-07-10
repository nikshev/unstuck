// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Test.sol";
import "../src/PrecisionDemo.sol";

contract PrecisionDemoTest is Test {
    function test_OLD_ShareInflation_RobsVictim() public {
        Attacker_OLD atk = new Attacker_OLD();
        atk.seed();                        // 1 wei -> 1 share
        atk.inflate();                     // donate 10,000 -> share price jumps
        emit log_named_uint("share price (inflated)", atk.sharePrice());
        assertEq(atk.sharePrice(), 10000, "1 share is now worth ~10,000");
        atk.victimDeposit();               // victim deposits 10,000
        emit log_named_uint("victim shares        ", atk.victimShares());
        assertEq(atk.victimShares(), 0, "victim rounded DOWN to ZERO shares");
        atk.steal();                       // attacker redeems the single share
        emit log_named_uint("attacker loot        ", atk.myLoot());
        assertEq(atk.myLoot(), 10000, "attacker took the victim's 10,000 deposit");
    }

    function test_FIXED_ZeroShareGuard_Reverts() public {
        Attacker_NEW atk = new Attacker_NEW();
        atk.seed();
        atk.inflate();
        vm.expectRevert(bytes("zero shares"));
        atk.victimDeposit();               // the guard rejects the 0-share deposit
        emit log_named_uint("victim shares (safe) ", atk.victimShares());
        assertEq(atk.victimShares(), 0, "victim never deposited -> keeps their money");
    }
}
