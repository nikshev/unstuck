// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {MockERC20} from "../src/MockERC20.sol";
import {IERC20} from "../src/IERC20.sol";
import {SignatureVault} from "../src/SignatureVault.sol";
import {SignatureVaultFixed} from "../src/SignatureVaultFixed.sol";
import {Replayer, IVault} from "../src/Replayer.sol";

/// Signature replay — HONEST -> ATTACK (replay one sig to drain) -> FIX (nonce+deadline+used).
contract SigReplayTest is Test {
    uint256 constant POT = 100_000e18;
    uint256 constant PAY = 100e18;
    uint256 opPk = 0xA11CE;            // operator (trusted signer) private key
    address operator;
    MockERC20 token;
    address alice;
    address attacker;

    function setUp() public { operator = vm.addr(opPk); token = new MockERC20("Reward", "RWD"); alice = makeAddr("alice"); attacker = makeAddr("attacker"); }

    // sign like the VULNERABLE vault expects: personal_sign over keccak256(to, amount)
    function _sigVuln(address to, uint256 amount) internal view returns (bytes memory) {
        bytes32 digest = keccak256(abi.encodePacked(to, amount));
        bytes32 eth    = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", digest));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(opPk, eth);
        return abi.encodePacked(r, s, v);
    }
    // sign the FIXED vault's EIP-712 digest
    function _sigFixed(SignatureVaultFixed vault, address to, uint256 amount, uint256 nonce, uint256 deadline)
        internal view returns (bytes memory) {
        bytes32 typeHash = keccak256("Claim(address to,uint256 amount,uint256 nonce,uint256 deadline)");
        bytes32 structHash = keccak256(abi.encode(typeHash, to, amount, nonce, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", vault.DOMAIN_SEPARATOR(), structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(opPk, digest);
        return abi.encodePacked(r, s, v);
    }

    function test_honest() public {
        console2.log("=== ACT 1: HONEST -- one signature, one payout ===");
        SignatureVault vault = new SignatureVault(IERC20(address(token)), operator);
        token.mint(address(vault), POT);
        console2.log("vault pot to pay from (RWD):", token.balanceOf(address(vault)) / 1e18);
        console2.log("operator signs: pay 100 to Alice");
        bytes memory sig = _sigVuln(alice, PAY);
        console2.log("Alice RWD before claim:", token.balanceOf(alice) / 1e18);
        vm.prank(alice); vault.claim(alice, PAY, sig);
        console2.log("Alice RWD after  claim:", token.balanceOf(alice) / 1e18, "(exactly the 100 authorized)");
        assertEq(token.balanceOf(alice), PAY);
    }

    function test_drain() public {
        console2.log("=== ACT 2: ATTACK -- replay ONE signature to drain ===");
        SignatureVault vault = new SignatureVault(IERC20(address(token)), operator);
        token.mint(address(vault), POT);
        Replayer r = new Replayer();
        console2.log("operator authorized ONE 100 payout to the attacker (one signature)");
        bytes memory sig = _sigVuln(attacker, PAY);
        console2.log("attacker RWD before:", token.balanceOf(attacker) / 1e18);
        vm.prank(attacker);
        r.drain(IVault(address(vault)), attacker, PAY, sig, 10);   // replay the same sig 10x in ONE tx
        console2.log("attacker RWD after replaying 10x:", token.balanceOf(attacker) / 1e18, "= 1,000 from a 100 authorization");
        console2.log("vault pot left:", token.balanceOf(address(vault)) / 1e18);
        assertEq(token.balanceOf(attacker), PAY * 10);
    }

    function test_fixed() public {
        console2.log("=== ACT 3: FIX -- domain + nonce + deadline + used ===");
        SignatureVaultFixed vault = new SignatureVaultFixed(IERC20(address(token)), operator);
        token.mint(address(vault), POT);
        uint256 nonce = 1; uint256 deadline = block.timestamp + 1 hours;
        bytes memory sig = _sigFixed(vault, attacker, PAY, nonce, deadline);
        console2.log("attacker RWD before:", token.balanceOf(attacker) / 1e18);
        vault.claim(attacker, PAY, nonce, deadline, sig);          // first use: pays 100
        console2.log("after first claim   :", token.balanceOf(attacker) / 1e18, "(the one authorized 100)");
        vm.expectRevert(bytes("used"));
        vault.claim(attacker, PAY, nonce, deadline, sig);          // replay: reverts
        console2.log("replay reverts with 'used' -- capped at the 100 authorized");
        assertEq(token.balanceOf(attacker), PAY);
    }
}
