// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// VULNERABLE: authorizes with tx.origin (the human who started the tx),
// NOT msg.sender (the immediate caller). Any contract the owner is tricked
// into calling can spend this wallet, because tx.origin is still the owner.
contract Wallet {
    address public owner;
    constructor() payable { owner = msg.sender; }

    function transferTo(address payable dest, uint256 amount) public {
        require(tx.origin == owner, "not owner");   // <-- the bug
        (bool ok, ) = dest.call{value: amount}("");
        require(ok, "send failed");
    }

    receive() external payable {}
}
