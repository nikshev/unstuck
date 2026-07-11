// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {Opportunity} from "../src/Opportunity.sol";

/// Proves WHY transaction order is worth money - the whole reason MEV exists.
contract PriorityGasAuctionTest is Test {
    Opportunity opp;
    address searcherA = makeAddr("searcherA"); // patient bot, bids LOW gas
    address searcherB = makeAddr("searcherB"); // aggressive bot, bids HIGH gas

    function setUp() public {
        opp = new Opportunity(); // a fresh 1 ETH opportunity before each test
    }

    /// Both bots want the same prize. B bids more gas, so the builder puts B FIRST.
    function test_higherGasGoesFirstAndWins() public {
        vm.prank(searcherB);              // B's tx is ordered first...
        uint256 bWon = opp.take();        // ...so B takes the whole prize
        console2.log("Searcher B (120 gwei) captured:", bWon);

        vm.prank(searcherA);              // A's tx runs second...
        vm.expectRevert("already taken"); // ...on a prize that is already gone
        opp.take();
        console2.log("Searcher A (5 gwei) arrived too late");

        assertEq(opp.winner(), searcherB); // the higher bidder won
    }

    /// Flip who pays more and the winner flips too: position is bought with gas.
    function test_ifAPaysMore_AGoesFirst_AWins() public {
        vm.prank(searcherA);
        opp.take();
        assertEq(opp.winner(), searcherA);
    }
}
