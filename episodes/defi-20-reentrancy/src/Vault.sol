// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice VULNERABLE ETH vault (The DAO class). You deposit ETH and can withdraw it.
/// BUG: withdraw() sends the ETH with an external call BEFORE it zeroes your recorded balance.
/// That external call hands control to the receiver's `receive()` while your balance still reads
/// full — so a malicious contract can RE-ENTER withdraw() again and again and drain the whole vault.
contract Vault {
    mapping(address => uint256) public balances;

    function deposit() external payable { balances[msg.sender] += msg.value; }

    function withdraw() external {
        uint256 bal = balances[msg.sender];
        require(bal > 0, "no balance");
        (bool ok, ) = msg.sender.call{value: bal}("");   // <-- INTERACTION before EFFECTS
        require(ok, "send failed");
        balances[msg.sender] = 0;                         // too late: re-entry already happened
    }

    receive() external payable {}
}
