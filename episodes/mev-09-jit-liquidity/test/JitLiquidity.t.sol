// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MockERC20} from "../src/MockERC20.sol";
import {IERC20} from "../src/IERC20.sol";
import {MiniPool} from "../src/MiniPool.sol";

/// @notice JIT (just-in-time) liquidity: a searcher mints a huge position one block before a big
/// swap, collects nearly all of that swap's fee, and burns -- capital at risk for a single block.
contract JitLiquidityTest is Test {
    MockERC20 t0;
    MockERC20 t1;
    MiniPool  pool;

    address passive = makeAddr("passiveLP");  // the honest, long-term liquidity provider
    address jit     = makeAddr("jitSearcher");// the JIT bot
    address trader  = makeAddr("trader");     // sends the big swap

    uint256 constant PASSIVE_LIQ = 100e18;    // baseline liquidity, always present
    uint256 constant JIT_LIQ     = 9_900e18;  // searcher floods the pool right before the swap
    uint256 constant SWAP_IN     = 50e18;     // a big token1 -> token0 swap
    // fee = 0.3% of SWAP_IN = 0.15e18 token1

    function setUp() public {
        t0 = new MockERC20("Token0", "T0");
        t1 = new MockERC20("Token1", "T1");
        pool = new MiniPool(IERC20(address(t0)), IERC20(address(t1)));
        _fund(passive, PASSIVE_LIQ);
        _fund(jit, JIT_LIQ);
        // trader needs token1 to swap in
        t1.mint(trader, SWAP_IN);
        vm.prank(trader); t1.approve(address(pool), type(uint256).max);
    }

    function _fund(address who, uint256 amt) internal {
        t0.mint(who, amt); t1.mint(who, amt);
        vm.startPrank(who);
        t0.approve(address(pool), type(uint256).max);
        t1.approve(address(pool), type(uint256).max);
        vm.stopPrank();
    }

    // Baseline: with no JIT, the passive LP earns the whole fee.
    function test_passive_baseline() public {
        vm.prank(passive); pool.addLiquidity(PASSIVE_LIQ);
        vm.prank(trader);  pool.swap(SWAP_IN);
        vm.prank(passive); uint256 got = pool.collect();
        console.log("passive-only, fee to passive LP:", got);
        assertApproxEqAbs(got, SWAP_IN * 3 / 1000, 1e6, "passive earns the full fee");
    }

    // JIT: searcher sandwiches the swap with add/remove and scoops ~all the fee.
    function test_jit_steals_fee() public {
        // passive LP is already in the pool
        vm.prank(passive); pool.addLiquidity(PASSIVE_LIQ);

        uint256 jitT0Before = t0.balanceOf(jit);
        uint256 jitT1Before = t1.balanceOf(jit);

        // ---- all in ONE block, around the trader's swap ----
        vm.startPrank(jit); pool.addLiquidity(JIT_LIQ); vm.stopPrank();   // 1. mint huge position
        vm.prank(trader);   pool.swap(SWAP_IN);                          // 2. the big swap pays the fee
        vm.startPrank(jit);
        uint256 jitFee = pool.collect();                                 // 3. collect ~all the fee
        pool.removeLiquidity(JIT_LIQ);                                   // 4. burn -- capital freed same block
        vm.stopPrank();

        vm.prank(passive); uint256 passiveFee = pool.collect();

        uint256 fee = SWAP_IN * 3 / 1000;
        console.log("swap fee total      :", fee);
        console.log("JIT searcher fee    :", jitFee);
        console.log("passive LP fee       :", passiveFee);
        console.log("JIT capital in/out t0:", jitT0Before, "->", t0.balanceOf(jit));

        // Searcher took ~99% of the fee; passive LP left with crumbs.
        assertGt(jitFee, fee * 98 / 100, "JIT scoops ~all the fee");
        assertLt(passiveFee, fee * 2 / 100, "passive LP diluted to near zero");
        // Capital was only ever committed for this one block (add + remove same block).
        assertApproxEqRel(t0.balanceOf(jit) + t1.balanceOf(jit),
                          jitT0Before + jitT1Before, 0.01e18, "searcher gets its capital back (~1 block risk)");
    }
}
