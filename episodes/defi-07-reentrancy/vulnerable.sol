// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// A simple ETH vault: deposit, then withdraw your balance.
// ❌ VULNERABLE — sends the ETH BEFORE zeroing the balance, so a malicious
//    receiver can re-enter withdraw() and drain the whole vault.
contract VaultVulnerable {
    mapping(address => uint256) public balance;
    function deposit() external payable { balance[msg.sender] += msg.value; }
    function withdraw() external {
        uint256 amt = balance[msg.sender];
        require(amt > 0, "no balance");
        (bool ok, ) = msg.sender.call{value: amt}("");   // interaction FIRST (the bug)
        require(ok, "send failed");
        balance[msg.sender] = 0;                          // effect LAST — too late
    }
}
