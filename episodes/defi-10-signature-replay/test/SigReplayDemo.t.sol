// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Test.sol";
import "../src/SigReplayDemo.sol";

contract SigReplayTest is Test {
    function test_OLD_SignatureReplay_DrainsPool() public {
        Attacker_OLD atk = new Attacker_OLD();
        assertEq(atk.poolLeft(), 1000);
        atk.claimOnce();                                 // 1 legit claim
        emit log_named_uint("pool after 1 legit claim", atk.poolLeft());
        assertEq(atk.poolLeft(), 900);
        atk.replayOnce();                                // SAME signature, again
        emit log_named_uint("pool after replaying it ", atk.poolLeft());
        assertEq(atk.poolLeft(), 800, "same sig paid twice");
        atk.drain();                                     // replay 8 more times
        emit log_named_uint("pool after full drain   ", atk.poolLeft());
        emit log_named_uint("attacker loot           ", atk.myLoot());
        assertEq(atk.poolLeft(), 0, "drained by replay");
        assertEq(atk.myLoot(), 1000);
    }

    function test_FIXED_SignatureReplay_Reverts() public {
        Attacker_NEW atk = new Attacker_NEW();
        atk.claimOnce();                                 // first claim ok
        vm.expectRevert(bytes("signature already used"));
        atk.replayOnce();                                // replay reverts
        emit log_named_uint("pool (intact)", atk.poolLeft());
        assertEq(atk.poolLeft(), 900);
    }
}
