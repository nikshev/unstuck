// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ✅ FIXED — only whitelisted targets may be called. One extra line closes the drain.
contract RouterFixed {
    address public owner;
    mapping(address => bool) public allowed;
    constructor() { owner = msg.sender; }

    function setAllowed(address t, bool ok) external {
        require(msg.sender == owner, "not owner");
        allowed[t] = ok;
    }

    function execute(address target, bytes calldata data) external returns (bytes memory) {
        require(allowed[target], "target not allowed");     // <-- THE FIX
        (bool ok, bytes memory ret) = target.call(data);
        require(ok, "call failed");
        return ret;
    }
}
