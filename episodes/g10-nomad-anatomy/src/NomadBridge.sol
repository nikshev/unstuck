// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MockToken} from "./MockToken.sol";

/// @title NomadBridge — a faithful, teaching-sized reproduction of the flaw that
/// drained the Nomad token bridge of ~$190M in August 2022.
///
/// A cross-chain bridge pays out a withdrawal on this chain only if the message
/// (recipient + amount) was PROVEN to belong to a Merkle root the operator has
/// CONFIRMED. That is the whole security model: no valid proof, no payout.
///
/// THE BUG (Nomad's botched 2022-06 upgrade): the routine upgrade left the ZERO
/// root marked as an acceptable/confirmed root. And any message that was never
/// proven has `provenRoot == 0` by default. So `process()` on a totally fabricated
/// message asks `acceptableRoot(0)` — and gets `true`. Every unproven message is
/// suddenly valid. Anyone could call `process()` with their own address as the
/// recipient and drain the bridge — no proof, no key, no cryptography broken.
contract NomadBridge {
    MockToken public token;
    address public operator;

    // root => unix time it becomes acceptable (0 = never confirmed)
    mapping(bytes32 => uint256) public confirmAt;
    // messageHash => the root it was proven against (0 = never proven)
    mapping(bytes32 => bytes32) public provenRoot;
    mapping(bytes32 => bool) public processed;

    event Processed(bytes32 indexed leaf, address indexed recipient, uint256 amount);

    constructor(MockToken _token) {
        token = _token;
        operator = msg.sender;
        // ---------------------------------------------------------------
        // THE BUG: the upgrade zeroed the trusted root AND marked it valid.
        // A zero root is now "acceptable since time 1" (the distant past).
        confirmAt[bytes32(0)] = 1;
        // ---------------------------------------------------------------
    }

    /// Operator confirms a real Merkle root that arrived from the other chain.
    function confirmRoot(bytes32 root) external {
        require(msg.sender == operator, "not operator");
        confirmAt[root] = block.timestamp;
    }

    /// A root is acceptable once it has been confirmed and its time has passed.
    function acceptableRoot(bytes32 root) public view returns (bool) {
        uint256 t = confirmAt[root];
        return t != 0 && block.timestamp >= t;
    }

    /// The message leaf binds who gets paid and how much.
    function messageHash(address recipient, uint256 amount) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(recipient, amount));
    }

    /// Prove a message belongs to a confirmed root (single-leaf tree: empty proof).
    function prove(address recipient, uint256 amount, bytes32 root, bytes32[] calldata proof) external {
        bytes32 leaf = messageHash(recipient, amount);
        require(_root(leaf, proof) == root, "bad proof");
        provenRoot[leaf] = root;
    }

    /// Pay out a proven message. Here is where the bug bites: an unproven message
    /// has provenRoot == 0, and acceptableRoot(0) returns true.
    function process(address recipient, uint256 amount) external {
        bytes32 leaf = messageHash(recipient, amount);
        require(!processed[leaf], "already processed");
        bytes32 root = provenRoot[leaf];
        require(acceptableRoot(root), "not proven");
        processed[leaf] = true;
        token.transfer(recipient, amount);
        emit Processed(leaf, recipient, amount);
    }

    function _root(bytes32 leaf, bytes32[] calldata proof) internal pure returns (bytes32) {
        bytes32 h = leaf;
        for (uint256 i; i < proof.length; i++) {
            h = keccak256(abi.encodePacked(h, proof[i]));
        }
        return h;
    }
}
