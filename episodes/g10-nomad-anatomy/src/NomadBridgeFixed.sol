// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MockToken} from "./MockToken.sol";

/// @title NomadBridgeFixed — identical to NomadBridge except for ONE guard.
/// A zero root can NEVER be acceptable. An unproven message (provenRoot == 0)
/// therefore fails, exactly as it always should have. That single line is the
/// difference between a working bridge and $190M gone.
contract NomadBridgeFixed {
    MockToken public token;
    address public operator;

    mapping(bytes32 => uint256) public confirmAt;
    mapping(bytes32 => bytes32) public provenRoot;
    mapping(bytes32 => bool) public processed;

    event Processed(bytes32 indexed leaf, address indexed recipient, uint256 amount);

    constructor(MockToken _token) {
        token = _token;
        operator = msg.sender;
        // Same botched upgrade — the zero root is still (wrongly) confirmed here...
        confirmAt[bytes32(0)] = 1;
    }

    function confirmRoot(bytes32 root) external {
        require(msg.sender == operator, "not operator");
        confirmAt[root] = block.timestamp;
    }

    function acceptableRoot(bytes32 root) public view returns (bool) {
        // ================= THE ONLY CHANGE =================
        // A zero root is never valid, no matter what confirmAt says. This blocks
        // every unproven (provenRoot == 0) message at the door.
        if (root == bytes32(0)) return false;
        // ===================================================
        uint256 t = confirmAt[root];
        return t != 0 && block.timestamp >= t;
    }

    function messageHash(address recipient, uint256 amount) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(recipient, amount));
    }

    function prove(address recipient, uint256 amount, bytes32 root, bytes32[] calldata proof) external {
        bytes32 leaf = messageHash(recipient, amount);
        require(_root(leaf, proof) == root, "bad proof");
        provenRoot[leaf] = root;
    }

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
