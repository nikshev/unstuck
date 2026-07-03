// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 { function transferFrom(address f, address t, uint256 a) external; }

contract TrustedVolumesFixed {
    address public owner;
    mapping(address => mapping(address => bool)) public allowedOrderSigner;
    mapping(bytes32 => bool) public usedOrder;   // replay guard, same slot in/out

    modifier onlyOwner() { require(msg.sender == owner, "not owner"); _; }

    struct Order {
        address maker; address taker; address makerAsset; uint256 amount; bytes32 nonce;
    }

    // FIX #1 — only governance registers trusted signers (not arbitrary callers).
    function registerAllowedOrderSigner(address maker, address signer, bool ok)
        external onlyOwner
    {
        allowedOrderSigner[maker][signer] = ok;
    }

    function fillOrder(Order calldata order, bytes calldata sig) external {
        address signer = recoverSigner(order, sig);

        // FIX #2 — validate the signer against the MAKER: the party whose funds move.
        require(allowedOrderSigner[order.maker][signer], "signer not allowed");

        bytes32 h = keccak256(abi.encode(order));
        require(!usedOrder[h], "replay");   // FIX #3 — one order, once
        usedOrder[h] = true;

        // funds go to the order's taker, not to an arbitrary msg.sender
        IERC20(order.makerAsset).transferFrom(order.maker, order.taker, order.amount);
    }

    function recoverSigner(Order calldata, bytes calldata) internal pure returns (address) {
        // ... EIP-712 typed-data recover, domain-bound ...
    }
}
