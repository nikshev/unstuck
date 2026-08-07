// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Counter.sol";

contract CounterTest is Test {
    Counter c;
    event Incremented(uint256 newCount);

    function setUp() public { c = new Counter(); }

    function test_starts_at_zero() public view {
        assertEq(c.count(), 0);
    }

    function test_increment_adds_one() public {
        c.increment();
        assertEq(c.count(), 1);
        c.increment();
        assertEq(c.count(), 2);
    }

    function test_increment_emits_event() public {
        vm.expectEmit(true, true, true, true);
        emit Incremented(1);
        c.increment();
    }
}
