// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ✅ FIXED — checks-effects-interactions: zero the balance BEFORE the call.
//    The re-entrant withdraw now sees 0 and reverts.
contract VaultFixed {
    mapping(address => uint256) public balance;
    function deposit() external payable { balance[msg.sender] += msg.value; }
    function withdraw() external {
        uint256 amt = balance[msg.sender];
        require(amt > 0, "no balance");
        balance[msg.sender] = 0;                          // effect FIRST (the fix)
        (bool ok, ) = msg.sender.call{value: amt}("");    // interaction LAST
        require(ok, "send failed");
    }
}
