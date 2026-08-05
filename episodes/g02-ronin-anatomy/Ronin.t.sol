// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./Bridge.sol";
import "./BridgeFixed.sol";

contract RoninTest is Test {
    uint256[] pk;            // 9 validator private keys, SORTED by their address asc
    address[] vals;          // matching validator addresses (asc)
    uint256 constant N = 9;
    uint256 constant THRESH = 5;
    address user = address(0xBEEF);
    address attacker = address(0xA11CE);

    function setUp() public {
        // 9 validators from private keys; sort by address so the bridge's
        // "sorted & distinct" signature check is satisfied by any prefix.
        uint256[] memory keys = new uint256[](N);
        address[] memory addrs = new address[](N);
        for (uint256 i; i < N; i++) { keys[i] = i + 1; addrs[i] = vm.addr(i + 1); }
        for (uint256 i; i < N; i++) for (uint256 j; j + 1 < N - i; j++)
            if (addrs[j] > addrs[j + 1]) {
                (addrs[j], addrs[j + 1]) = (addrs[j + 1], addrs[j]);
                (keys[j], keys[j + 1]) = (keys[j + 1], keys[j]);
            }
        for (uint256 i; i < N; i++) { pk.push(keys[i]); vals.push(addrs[i]); }
    }

    // Sign a withdrawal with the first `k` (sorted) validator keys -> sigs asc by addr.
    function _sign(bytes32 d, uint256 k) internal view returns (bytes[] memory sigs) {
        sigs = new bytes[](k);
        for (uint256 i; i < k; i++) {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk[i], d);
            sigs[i] = abi.encodePacked(r, s, v);
        }
    }

    // ── ACT 1 — HONEST: 5 of 9 real validators approve a legit user withdrawal ──
    function test_1_honest() public {
        Bridge b = new Bridge{value: 100 ether}(vals, THRESH);
        emit log_named_decimal_uint("bridge before        ", address(b).balance, 18);
        bytes32 d = b.digest(user, 10 ether, 1);
        b.withdraw(user, 10 ether, 1, _sign(d, THRESH));
        emit log_named_decimal_uint("bridge after (honest)", address(b).balance, 18);
        emit log_named_decimal_uint("user received        ", user.balance, 18);
        assertEq(address(b).balance, 90 ether);
        assertEq(user.balance, 10 ether);
    }

    // ── ACT 2 — ATTACK: the attacker STOLE 5 validator keys -> signs a withdrawal
    //    to themselves. Same mechanism, real signatures, the bridge can't tell. ──
    function test_2_attack() public {
        Bridge b = new Bridge{value: 100 ether}(vals, THRESH);
        emit log_named_decimal_uint("bridge before        ", address(b).balance, 18);
        emit log_named_decimal_uint("attacker before      ", attacker.balance, 18);
        // attacker controls the keys pk[0..4] (5 of 9) -> forge a withdrawal to self
        bytes32 d = b.digest(attacker, 100 ether, 1);
        b.withdraw(attacker, 100 ether, 1, _sign(d, THRESH));
        emit log_named_decimal_uint("bridge after (DRAIN) ", address(b).balance, 18);
        emit log_named_decimal_uint("attacker after       ", attacker.balance, 18);
        assertEq(address(b).balance, 0);
        assertEq(attacker.balance, 100 ether);
    }

    // ── ACT 3 — FIX: same forged signatures, but the large withdrawal is time-locked
    //    and the guardian pauses the bridge before it can execute. Funds are safe. ──
    function test_3_fixed() public {
        address guardian = address(0x617A);
        BridgeFixed b = new BridgeFixed{value: 100 ether}(vals, THRESH, guardian, 1 days, 10 ether);
        bytes32 d = b.digest(attacker, 100 ether, 1);
        // attacker's forged (but valid) withdrawal — QUEUED, not paid
        b.withdraw(attacker, 100 ether, 1, _sign(d, THRESH));
        emit log_named_decimal_uint("bridge after queue   ", address(b).balance, 18);
        assertEq(address(b).balance, 100 ether, "nothing moved yet");
        // guardian spots the pending drain and freezes the bridge
        vm.prank(guardian);
        b.pause();
        // even after the delay, execution is blocked
        vm.warp(block.timestamp + 1 days + 1);
        vm.expectRevert(bytes("bridge paused"));
        b.execute(d);
        emit log_named_decimal_uint("bridge after (SAFE)  ", address(b).balance, 18);
        emit log_named_decimal_uint("attacker got         ", attacker.balance, 18);
        assertEq(address(b).balance, 100 ether);
        assertEq(attacker.balance, 0);
    }
}
