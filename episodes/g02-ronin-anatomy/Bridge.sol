// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// A minimal Ronin-style bridge. Funds are LOCKED here; to withdraw them, a set
/// of VALIDATORS must sign the withdrawal. Ronin required 5-of-9 signatures.
/// The contract is CORRECT — the security IS the validator keys. Compromise
/// enough keys and the signatures are perfectly real, so a forged withdrawal to
/// the attacker looks identical to a legitimate one. That is exactly the March
/// 2022 hack: no contract bug, the keys themselves were stolen.
contract Bridge {
    address[] public validators;
    uint256 public threshold;
    mapping(bytes32 => bool) public used;

    event Withdraw(address indexed to, uint256 amount, uint256 nonce);

    constructor(address[] memory _validators, uint256 _threshold) payable {
        validators = _validators;
        threshold = _threshold;
    }

    function isValidator(address a) public view returns (bool) {
        for (uint256 i; i < validators.length; i++) if (validators[i] == a) return true;
        return false;
    }

    function digest(address to, uint256 amount, uint256 nonce) public view returns (bytes32) {
        bytes32 h = keccak256(abi.encodePacked(to, amount, nonce, address(this)));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
    }

    /// Release `amount` to `to` if at least `threshold` distinct validators signed it.
    function withdraw(address to, uint256 amount, uint256 nonce, bytes[] calldata sigs) external {
        bytes32 d = digest(to, amount, nonce);
        require(!used[d], "already used");
        uint256 count;
        address last;
        for (uint256 i; i < sigs.length; i++) {
            address signer = _recover(d, sigs[i]);
            require(isValidator(signer), "not a validator");
            require(uint160(signer) > uint160(last), "unsorted or duplicate"); // distinct + sorted
            last = signer;
            count++;
        }
        require(count >= threshold, "not enough signatures");
        used[d] = true;
        (bool ok, ) = to.call{value: amount}("");
        require(ok, "transfer failed");
        emit Withdraw(to, amount, nonce);
    }

    function _recover(bytes32 d, bytes memory sig) internal pure returns (address) {
        require(sig.length == 65, "bad sig length");
        bytes32 r; bytes32 s; uint8 v;
        assembly { r := mload(add(sig, 32)) s := mload(add(sig, 64)) v := byte(0, mload(add(sig, 96))) }
        return ecrecover(d, v, r, s);
    }

    receive() external payable {}
}
