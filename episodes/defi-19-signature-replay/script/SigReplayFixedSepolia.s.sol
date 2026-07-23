// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {MockERC20} from "../src/MockERC20.sol";
import {IERC20} from "../src/IERC20.sol";
import {SignatureVaultFixed} from "../src/SignatureVaultFixed.sol";

// ACT 3 — Sepolia deploy of the FIXED vault (EIP-712 + nonce + deadline + used).
contract SigReplayFixedSepolia is Script {
    uint256 constant POT = 100_000e18;
    function run() external {
        vm.startBroadcast();
        MockERC20 token = new MockERC20("Reward", "RWD");
        SignatureVaultFixed vault = new SignatureVaultFixed(IERC20(address(token)), msg.sender);
        token.mint(address(vault), POT);
        vm.stopBroadcast();
        console2.log("TOKEN=%s", address(token));
        console2.log("VAULT=%s", address(vault));
        console2.log("OPERATOR=%s", msg.sender);
    }
}
