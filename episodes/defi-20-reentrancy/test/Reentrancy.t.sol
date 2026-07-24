// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {Vault} from "../src/Vault.sol";
import {VaultFixed} from "../src/VaultFixed.sol";
import {Attacker} from "../src/Attacker.sol";
import {IVault} from "../src/Attacker.sol";

/// Classic reentrancy (The DAO) — HONEST -> ATTACK (re-enter, drain) -> FIX (checks-effects-interactions).
contract ReentrancyTest is Test {
    uint256 constant U = 0.01 ether;
    address alice; address bob; address attackerEOA;

    function setUp() public { alice=makeAddr("alice"); bob=makeAddr("bob"); attackerEOA=makeAddr("attackerEOA"); }

    function test_honest() public {
        console2.log("=== ACT 1: HONEST -- deposit then withdraw, normally ===");
        Vault v = new Vault();
        vm.deal(alice, 3*U);
        vm.prank(alice); v.deposit{value: 3*U}();
        console2.log("Alice deposited (x0.01 ETH): 3 | vault holds:", address(v).balance / U);
        vm.prank(alice); v.withdraw();
        console2.log("Alice withdrew; her balance back (x0.01):", alice.balance / U, "| vault now:", address(v).balance / U);
        assertEq(alice.balance, 3*U);
        assertEq(address(v).balance, 0);
    }

    function test_drain() public {
        console2.log("=== ACT 2: ATTACK -- re-enter withdraw() and drain the vault ===");
        Vault v = new Vault();
        vm.deal(alice, 3*U); vm.prank(alice); v.deposit{value: 3*U}();
        vm.deal(bob, 2*U);   vm.prank(bob);   v.deposit{value: 2*U}();
        console2.log("honest deposits in the vault (x0.01):", address(v).balance / U);   // 5
        Attacker atk = new Attacker(IVault(address(v)));
        vm.deal(attackerEOA, U);
        vm.prank(attackerEOA); atk.attack{value: U}();       // seed 1, then drain
        console2.log("attacker contract balance after attack (x0.01):", address(atk).balance / U); // 6
        console2.log("vault left (x0.01):", address(v).balance / U);                                // 0
        assertEq(address(atk).balance, 6*U);   // its own 1 + the honest 5
        assertEq(address(v).balance, 0);
    }

    function test_fixed() public {
        console2.log("=== ACT 3: FIX -- checks-effects-interactions + a lock ===");
        VaultFixed v = new VaultFixed();
        vm.deal(alice, 3*U); vm.prank(alice); v.deposit{value: 3*U}();
        vm.deal(bob, 2*U);   vm.prank(bob);   v.deposit{value: 2*U}();
        console2.log("honest deposits in the FIXED vault (x0.01):", address(v).balance / U);  // 5
        Attacker atk = new Attacker(IVault(address(v)));
        vm.deal(attackerEOA, U);
        vm.prank(attackerEOA); atk.attack{value: U}();
        console2.log("attacker contract balance after attack (x0.01):", address(atk).balance / U); // 1
        console2.log("vault still holds the honest funds (x0.01):", address(v).balance / U);        // 5
        assertEq(address(atk).balance, U);       // only its own unit back
        assertEq(address(v).balance, 5*U);       // honest funds untouched
    }
}
