// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// FIXED: authorizes with msg.sender — the immediate caller. A middle
// contract calling in is msg.sender != owner, so the phish reverts.
contract SafeWallet {
    address public owner;
    constructor() payable { owner = msg.sender; }

    function transferTo(address payable dest, uint256 amount) public {
        require(msg.sender == owner, "not owner");  // <-- the fix
        (bool ok, ) = dest.call{value: amount}("");
        require(ok, "send failed");
    }

    receive() external payable {}
}
