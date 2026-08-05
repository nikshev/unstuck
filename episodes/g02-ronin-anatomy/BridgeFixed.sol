// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// The fix. A stolen-key attack can't be stopped by the multisig itself — the
/// signatures are real. So we add two things every serious bridge now has:
///   1) a TIME-LOCK: any large withdrawal is QUEUED, not instant;
///   2) a GUARDIAN that can PAUSE during the delay window.
/// This turns an instant $625M drain into a slow, catchable event: the forged
/// withdrawal still "passes" the signatures, but it waits — and a watching
/// guardian freezes it before a single coin leaves.
contract BridgeFixed {
    address[] public validators;
    uint256 public threshold;
    mapping(bytes32 => bool) public used;

    address public guardian;
    uint256 public delay;      // e.g. 24h
    uint256 public bigAmount;  // withdrawals above this are time-locked
    bool public paused;

    struct Pending { address to; uint256 amount; uint256 eta; bool exists; }
    mapping(bytes32 => Pending) public queued;

    event Queued(bytes32 id, address to, uint256 amount, uint256 eta);
    event Executed(bytes32 id);
    event Paused();

    constructor(address[] memory _v, uint256 _t, address _guardian, uint256 _delay, uint256 _big) payable {
        validators = _v; threshold = _t; guardian = _guardian; delay = _delay; bigAmount = _big;
    }

    function isValidator(address a) public view returns (bool) {
        for (uint256 i; i < validators.length; i++) if (validators[i] == a) return true;
        return false;
    }
    function digest(address to, uint256 amount, uint256 nonce) public view returns (bytes32) {
        bytes32 h = keccak256(abi.encodePacked(to, amount, nonce, address(this)));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
    }
    function pause() external { require(msg.sender == guardian, "not guardian"); paused = true; emit Paused(); }

    function _verify(bytes32 d, bytes[] calldata sigs) internal view {
        uint256 count; address last;
        for (uint256 i; i < sigs.length; i++) {
            address signer = _recover(d, sigs[i]);
            require(isValidator(signer), "not a validator");
            require(uint160(signer) > uint160(last), "unsorted or duplicate");
            last = signer; count++;
        }
        require(count >= threshold, "not enough signatures");
    }

    /// Small withdrawals pay instantly; large ones are queued behind the delay.
    function withdraw(address to, uint256 amount, uint256 nonce, bytes[] calldata sigs) external {
        bytes32 d = digest(to, amount, nonce);
        require(!used[d], "already used");
        _verify(d, sigs);
        used[d] = true;
        if (amount > bigAmount) {
            uint256 eta = block.timestamp + delay;
            queued[d] = Pending(to, amount, eta, true);
            emit Queued(d, to, amount, eta);
        } else {
            (bool ok, ) = to.call{value: amount}(""); require(ok, "transfer failed");
        }
    }

    /// Anyone can execute a queued withdrawal — but only after the delay, and only
    /// if the guardian hasn't frozen the bridge in the meantime.
    function execute(bytes32 d) external {
        Pending memory p = queued[d];
        require(p.exists, "no such withdrawal");
        require(block.timestamp >= p.eta, "still time-locked");
        require(!paused, "bridge paused");
        delete queued[d];
        (bool ok, ) = p.to.call{value: p.amount}(""); require(ok, "transfer failed");
        emit Executed(d);
    }

    function _recover(bytes32 d, bytes memory sig) internal pure returns (address) {
        require(sig.length == 65, "bad sig length");
        bytes32 r; bytes32 s; uint8 v;
        assembly { r := mload(add(sig, 32)) s := mload(add(sig, 64)) v := byte(0, mload(add(sig, 96))) }
        return ecrecover(d, v, r, s);
    }
    receive() external payable {}
}
