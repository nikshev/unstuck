// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {MockERC20} from "../src/MockERC20.sol";
import {IERC20} from "../src/IERC20.sol";
import {SignatureVault} from "../src/SignatureVault.sol";
import {Replayer} from "../src/Replayer.sol";

// ACT 1+2 — Sepolia deploy of the VULNERABLE vault. The deployer is the operator/signer.
// claim() + Replayer.drain() are sent afterward with cast (real signatures via `cast wallet sign`).
contract SigReplaySepolia is Script {
    uint256 constant POT = 100_000e18;
    function run() external {
        vm.startBroadcast();
        MockERC20 token = new MockERC20("Reward", "RWD");
        SignatureVault vault = new SignatureVault(IERC20(address(token)), msg.sender);
        token.mint(address(vault), POT);
        Replayer rep = new Replayer();
        vm.stopBroadcast();
        console2.log("TOKEN=%s", address(token));
        console2.log("VAULT=%s", address(vault));
        console2.log("REPLAYER=%s", address(rep));
        console2.log("OPERATOR=%s", msg.sender);
    }
}
