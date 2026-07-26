// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Test.sol";
import "../src/Pool.sol";

// Same victim swap, two worlds. PUBLIC mempool: the searcher sees the victim's
// buy and wraps it (front-run buy -> victim buy -> back-run sell) for profit,
// leaving the victim fewer tokens. PRIVATE orderflow: the victim's tx is hidden
// from the searcher (mined directly), so there is nothing to sandwich.
contract SandwichTest is Test {
    uint256 constant W = 100e18;      // 100 WETH
    uint256 constant T = 300000e18;   // 300k TOKEN

    function _fresh() internal returns(Pool){ return new Pool(W, T); }

    // PUBLIC mempool: victim gets sandwiched
    function test_public_sandwich() public {
        Pool p = _fresh();
        uint256 victimIn = 5e18;                 // victim buys with 5 WETH
        uint256 frontIn  = 20e18;                // searcher front-runs with 20 WETH
        uint256 gotFront = p.buy(frontIn);       // 1) front-run buy (pushes price up)
        uint256 gotVictim = p.buy(victimIn);     // 2) victim buys at the worse price
        uint256 back = p.sell(gotFront);         // 3) back-run sell the front-run tokens
        int256 searcherProfit = int256(back) - int256(frontIn);
        console.log("PUBLIC  victim received TOKEN:", gotVictim/1e18);
        console.log("PUBLIC  searcher profit (WETH, may wrap if negative):");
        console.logInt(searcherProfit/1e18);
        // stash for comparison
        victimPublic = gotVictim;
    }
    uint256 victimPublic;

    // PRIVATE orderflow: the victim's buy is mined alone -> fair price
    function test_private_orderflow() public {
        Pool p = _fresh();
        uint256 victimIn = 5e18;
        uint256 gotVictim = p.buy(victimIn);     // no front-run, no back-run
        console.log("PRIVATE victim received TOKEN:", gotVictim/1e18);
        // re-run the public path inline to compare in one test
        Pool q = _fresh();
        q.buy(20e18); uint256 sandwiched = q.buy(victimIn);
        console.log("  (same swap, PUBLIC would give:", sandwiched/1e18, "TOKEN)");
        assertGt(gotVictim, sandwiched);         // private buyer keeps more
    }
}
