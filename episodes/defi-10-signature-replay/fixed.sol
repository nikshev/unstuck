// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ✅ FIXED — record each signature and reject it the second time (one-time use).
// (Production: prefer a per-account nonce + EIP-712 typed data bound to chainid + contract + deadline.)
contract VaultFixed {
    address public signer;
    uint256 public pool;
    mapping(address => uint256) public paid;
    mapping(bytes32 => bool) public used;
    constructor(address _signer, uint256 _pool) { signer = _signer; pool = _pool; }
    function claim(address to, uint256 amount, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 hash = keccak256(abi.encodePacked(to, amount));
        require(ecrecover(hash, v, r, s) == signer, "bad signature");
        bytes32 sigId = keccak256(abi.encodePacked(r, s, v));
        require(!used[sigId], "signature already used");   // <-- reject a replay
        used[sigId] = true;                                // <-- one-time use
        require(amount <= pool, "insufficient pool");
        pool -= amount;
        paid[to] += amount;
    }
}
