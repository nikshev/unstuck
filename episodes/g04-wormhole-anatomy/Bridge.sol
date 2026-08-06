// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// A minimal Wormhole-style token bridge. When you deposit on Ethereum, a set of
/// off-chain "guardians" watch it and sign a message (a VAA) attesting to it.
/// Show this bridge that VAA with enough guardian signatures, and it MINTS you the
/// wrapped token on this side. Wormhole used 19 guardians; 13 signatures = quorum.
///
/// THE BUG (Feb 2022, $325M): the signature check trusted the WRONG thing. Here we
/// model it faithfully — the bridge verifies the signatures against a guardian set
/// the CALLER hands in, instead of its own real, stored set. So an attacker just
/// supplies their own "guardians" and their own signatures. The check passes, and
/// the bridge mints wrapped tokens that were never backed by a real deposit.
contract Bridge {
    address[] public guardians;   // the REAL guardian set (set once, at deploy)
    uint256 public quorum;
    mapping(bytes32 => bool) public used;
    mapping(address => uint256) public balanceOf;   // wrapped wETH minted by the bridge
    uint256 public totalSupply;

    event Mint(address indexed to, uint256 amount);

    constructor(address[] memory _guardians, uint256 _quorum) {
        guardians = _guardians; quorum = _quorum;
    }

    function digest(address to, uint256 amount, uint256 nonce) public view returns (bytes32) {
        bytes32 h = keccak256(abi.encodePacked(to, amount, nonce, address(this)));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
    }

    /// Mint wrapped tokens for a deposit attested by the guardians.
    /// BUG: `claimedGuardians` is supplied by the caller and never checked against the
    /// real `guardians`. Sign with any keys you like, call them "guardians", and pass.
    function receiveAndMint(
        address to, uint256 amount, uint256 nonce,
        address[] calldata claimedGuardians, bytes[] calldata sigs
    ) external {
        bytes32 d = digest(to, amount, nonce);
        require(!used[d], "already minted");
        uint256 count; address last;
        for (uint256 i; i < sigs.length; i++) {
            address signer = _recover(d, sigs[i]);
            require(_in(claimedGuardians, signer), "not a guardian");   // <-- caller's set!
            require(uint160(signer) > uint160(last), "unsorted/dup");
            last = signer; count++;
        }
        require(count >= quorum, "not enough signatures");
        used[d] = true;
        balanceOf[to] += amount; totalSupply += amount;
        emit Mint(to, amount);
    }

    function _in(address[] calldata set, address a) internal pure returns (bool) {
        for (uint256 i; i < set.length; i++) if (set[i] == a) return true;
        return false;
    }
    function _recover(bytes32 d, bytes memory sig) internal pure returns (address) {
        require(sig.length == 65, "bad sig");
        bytes32 r; bytes32 s; uint8 v;
        assembly { r := mload(add(sig,32)) s := mload(add(sig,64)) v := byte(0,mload(add(sig,96))) }
        return ecrecover(d, v, r, s);
    }
}
