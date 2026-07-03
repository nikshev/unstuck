// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ILLUSTRATIVE reconstruction of the TrustedVolumes RFQ settlement drain (2026, ~$5.87M).
// This is a minimal teaching model of the TWO flaws — not the real bytecode.

interface IERC20 { function transferFrom(address f, address t, uint256 a) external; }

contract TrustedVolumesVulnerable {
    // account => (signer => trusted?)  — who may sign orders on your behalf
    mapping(address => mapping(address => bool)) public allowedOrderSigner;

    struct Order {
        address maker;       // whose pre-approved funds move OUT
        address taker;       // the counterparty (receives / attacker)
        address makerAsset;  // the token to pull from the maker
        uint256 amount;
    }

    // FLAW #1 — no access control: ANYONE can register ANY signer for themselves.
    function registerAllowedOrderSigner(address signer, bool allowed) external {
        allowedOrderSigner[msg.sender][signer] = allowed;
    }

    function fillOrder(Order calldata order, bytes calldata sig) external {
        address signer = recoverSigner(order, sig);

        // FLAW #2 — checks the TAKER's trust list, but pulls funds from the MAKER.
        // Authorization and the debited account are DIFFERENT parties.
        require(allowedOrderSigner[order.taker][signer], "signer not allowed");

        // maker's pre-approved balance is transferred out to msg.sender (the attacker)
        IERC20(order.makerAsset).transferFrom(order.maker, msg.sender, order.amount);
    }

    function recoverSigner(Order calldata, bytes calldata) internal pure returns (address) {
        // ... ECDSA recover of the order signature ...
    }
}
