// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice FIXED vault. Checks-Effects-Interactions: zero the balance BEFORE the external call
/// (plus a simple reentrancy lock). A re-entrant withdraw now sees a zero balance and does nothing,
/// so the drain is impossible.
contract VaultFixed {
    mapping(address => uint256) public balances;
    bool private locked;
    modifier nonReentrant() { require(!locked, "reentrant"); locked = true; _; locked = false; }

    function deposit() external payable { balances[msg.sender] += msg.value; }

    function withdraw() external nonReentrant {
        uint256 bal = balances[msg.sender];
        require(bal > 0, "no balance");
        balances[msg.sender] = 0;                         // EFFECTS first
        (bool ok, ) = msg.sender.call{value: bal}("");    // INTERACTION last
        require(ok, "send failed");
    }

    receive() external payable {}
}
