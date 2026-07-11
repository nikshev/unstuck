// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ❌ VULNERABLE — a payout vault. A trusted SIGNER approves "pay `amount` to `to`" by signing it;
// the recipient submits that signature to claim. It verifies the signature is VALID, but never
// records that a signature was USED — so the exact same signature can be REPLAYED to drain the pool.
contract Vault {
    address public signer;
    uint256 public pool;
    mapping(address => uint256) public paid;
    constructor(address _signer, uint256 _pool) { signer = _signer; pool = _pool; }
    function claim(address to, uint256 amount, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 hash = keccak256(abi.encodePacked(to, amount));
        require(ecrecover(hash, v, r, s) == signer, "bad signature");   // valid? yes. used before? never asked.
        require(amount <= pool, "insufficient pool");
        pool -= amount;
        paid[to] += amount;
    }
}
