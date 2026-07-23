// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {IERC20} from "./IERC20.sol";

/// @notice FIXED payout vault. The signature is now bound to THIS contract and THIS chain
/// (EIP-712 domain), carries a per-claim `nonce` and a `deadline`, and each resulting digest is
/// marked used the first time it pays. Replaying the same signature reverts with "used".
contract SignatureVaultFixed {
    IERC20  public immutable token;
    address public immutable operator;
    bytes32 public immutable DOMAIN_SEPARATOR;
    mapping(bytes32 => bool) public used;

    bytes32 private constant CLAIM_TYPEHASH =
        keccak256("Claim(address to,uint256 amount,uint256 nonce,uint256 deadline)");

    constructor(IERC20 _t, address _op) {
        token = _t; operator = _op;
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)"),
            keccak256(bytes("SignatureVault")), block.chainid, address(this)));
    }

    function claim(address to, uint256 amount, uint256 nonce, uint256 deadline, bytes calldata sig) external {
        require(block.timestamp <= deadline, "expired");
        bytes32 structHash = keccak256(abi.encode(CLAIM_TYPEHASH, to, amount, nonce, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
        require(!used[digest], "used");        // <-- one signature, one payout
        used[digest] = true;
        require(_recover(digest, sig) == operator, "bad sig");
        token.transfer(to, amount);
    }

    function _recover(bytes32 h, bytes calldata sig) internal pure returns (address) {
        require(sig.length == 65, "len");
        bytes32 r; bytes32 s; uint8 v;
        assembly {
            r := calldataload(sig.offset)
            s := calldataload(add(sig.offset, 32))
            v := byte(0, calldataload(add(sig.offset, 64)))
        }
        return ecrecover(h, v, r, s);
    }
}
