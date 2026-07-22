// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MockERC20} from "../src/MockERC20.sol";
import {IERC20} from "../src/IERC20.sol";
import {MiniPool} from "../src/MiniPool.sol";
import {MiniPoolTW} from "../src/MiniPoolTW.sol";

/// @notice Three acts, each logging who earns what fee:
///   1. test_passive  — a passive LP earns the WHOLE swap fee (the normal flow)
///   2. test_jit      — a JIT searcher wraps the swap and takes ~99% of the fee
///   3. test_defended — time-weighted fees -> the one-block JIT earns ~0, passive keeps it
contract JitLiquidityTest is Test {
    MockERC20 t0;
    MockERC20 t1;
    address passive = makeAddr("passiveLP");
    address jit     = makeAddr("jitSearcher");
    address trader  = makeAddr("trader");

    uint256 constant PLIQ = 100_000e18;     // passive, standing liquidity
    uint256 constant JLIQ = 9_900_000e18;   // JIT floods in -> 99% of the pool
    uint256 constant SWAP = 100_000e18;     // a big swap; fee = 0.3% = 300 T1

    function setUp() public {
        t0 = new MockERC20("Token0", "T0");
        t1 = new MockERC20("Token1", "T1");
    }
    function _fund(address who, uint256 amt, address pool) internal {
        t0.mint(who, amt); t1.mint(who, amt);
        vm.startPrank(who);
        t0.approve(pool, type(uint256).max);
        t1.approve(pool, type(uint256).max);
        vm.stopPrank();
    }

    // -----------------------------------------------------------------------
    // ACT 1 — the passive LP earns the whole fee (this is the normal flow)
    // -----------------------------------------------------------------------
    function test_passive() public {
        MiniPool pool = new MiniPool(IERC20(address(t0)), IERC20(address(t1)));
        _fund(passive, PLIQ, address(pool));
        t1.mint(trader, SWAP);
        vm.prank(trader); t1.approve(address(pool), type(uint256).max);

        console.log("=== ACT 1: PASSIVE LP (the normal flow) ===");
        vm.prank(passive); pool.addLiquidity(PLIQ);
        console.log("passive LP provides liquidity:", PLIQ / 1e18);
        console.log("a trader swaps T1 in:         ", SWAP / 1e18);
        console.log("swap fee (0.3%) T1:           ", SWAP * 3 / 1000 / 1e18);
        vm.prank(trader); pool.swap(SWAP);
        vm.prank(passive); uint256 got = pool.collect();
        console.log("passive LP collects fee (T1): ", got / 1e18);
        console.log("-> the passive LP earns the WHOLE fee, for providing the liquidity");

        assertApproxEqAbs(got, SWAP * 3 / 1000, 1e15, "passive earns the full fee");
    }

    // -----------------------------------------------------------------------
    // ACT 2 — JIT: mint huge one block before the swap, take ~all the fee, burn
    // -----------------------------------------------------------------------
    function test_jit() public {
        MiniPool pool = new MiniPool(IERC20(address(t0)), IERC20(address(t1)));
        _fund(passive, PLIQ, address(pool));
        _fund(jit, JLIQ, address(pool));
        t1.mint(trader, SWAP);
        vm.prank(trader); t1.approve(address(pool), type(uint256).max);

        console.log("=== ACT 2: JIT LIQUIDITY ===");
        vm.prank(passive); pool.addLiquidity(PLIQ);
        console.log("passive LP liquidity (standing):", PLIQ / 1e18);
        console.log("swap fee to share (T1):         ", SWAP * 3 / 1000 / 1e18);
        console.log("--- all in ONE block, around the swap ---");
        vm.prank(jit); pool.addLiquidity(JLIQ);
        console.log("JIT searcher mints (just before):", JLIQ / 1e18);
        console.log("pool now: JIT owns 9,900,000 / 10,000,000 = ~99%");
        vm.prank(trader); pool.swap(SWAP);
        vm.prank(jit); uint256 jitFee = pool.collect();
        vm.prank(jit); pool.removeLiquidity(JLIQ);
        vm.prank(passive); uint256 passFee = pool.collect();
        console.log("JIT searcher collects (T1):     ", jitFee / 1e18);
        console.log("passive LP collects (T1):       ", passFee / 1e18);
        console.log("-> JIT took ~99%; the passive LP that stood the whole time got ~1%");

        assertGt(jitFee, SWAP * 3 / 1000 * 98 / 100, "JIT scoops ~all the fee");
        assertLt(passFee, SWAP * 3 / 1000 * 2 / 100, "passive diluted to a sliver");
    }

    // -----------------------------------------------------------------------
    // ACT 3 — DEFENSE: time-weighted fees -> a one-block JIT earns ~0
    // -----------------------------------------------------------------------
    function test_defended() public {
        MiniPoolTW pool = new MiniPoolTW(IERC20(address(t0)), IERC20(address(t1)));
        _fund(passive, PLIQ, address(pool));
        _fund(jit, JLIQ, address(pool));
        t1.mint(trader, SWAP);
        vm.prank(trader); t1.approve(address(pool), type(uint256).max);

        console.log("=== ACT 3: DEFENSE (time-weighted fees) ===");
        vm.prank(passive); pool.addLiquidity(PLIQ);
        console.log("passive LP provides liquidity:  ", PLIQ / 1e18);
        vm.warp(block.timestamp + 1 days);     // the passive LP actually stays for a day
        console.log("...the passive LP stays 1 day (real time in the pool)...");
        console.log("--- now the JIT tries the same move, all in ONE block ---");
        vm.prank(jit); pool.addLiquidity(JLIQ);
        console.log("JIT searcher mints (just before):", JLIQ / 1e18);
        vm.prank(trader); pool.swap(SWAP);
        vm.prank(jit); uint256 jitFee = pool.collect();
        vm.prank(jit); pool.removeLiquidity(JLIQ);
        vm.prank(passive); uint256 passFee = pool.collect();
        console.log("JIT time-in-pool: 0 seconds -> ~0 liquidity-seconds");
        console.log("JIT searcher collects (T1):     ", jitFee / 1e18);
        console.log("passive LP collects (T1):       ", passFee / 1e18);
        console.log("-> the one-block JIT earns ~nothing; the passive LP keeps the fee");

        assertLt(jitFee, SWAP * 3 / 1000 / 1000, "JIT earns ~0 on the time-weighted pool");
        assertGt(passFee, SWAP * 3 / 1000 * 95 / 100, "passive keeps ~all the fee");
    }
}
