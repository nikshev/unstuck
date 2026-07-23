// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {IERC20} from "./IERC20.sol";

/// @notice VULNERABLE payout vault. You withdraw `amount` to `to` by presenting a message the
/// operator signed. BUG: the signed digest is only keccak256(to, amount) — NO nonce, NO deadline,
/// NO domain, and nothing marks a signature as used. The signature is public in the tx calldata,
/// so ANYONE can REPLAY it again and again, draining far more than the operator ever authorized.
contract SignatureVault {
    IERC20  public immutable token;
    address public immutable operator;   // the trusted signer
    constructor(IERC20 _t, address _op) { token = _t; operator = _op; }

    function claim(address to, uint256 amount, bytes calldata sig) external {
        bytes32 digest    = keccak256(abi.encodePacked(to, amount));
        bytes32 ethSigned = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", digest));
        require(_recover(ethSigned, sig) == operator, "bad sig");
        token.transfer(to, amount);      // <-- no used/nonce check: replay pays again every time
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
