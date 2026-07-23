// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {Salmonella} from "../src/Salmonella.sol";
import {SafeReceiver, ISalm} from "../src/SafeReceiver.sol";

/// Salmonella honeypot — HONEST (owner moves full) -> TRAP (front-runner: event lies, 1% arrives)
/// -> FIX (verify the balance delta -> revert on the short transfer).
contract SalmonellaTest is Test {
    Salmonella salm;
    address owner;
    address bob;
    address sink;
    address bot;

    function setUp() public {
        owner = address(this);            // the deployer is the honeypot owner
        salm  = new Salmonella();
        bob   = makeAddr("bob");
        sink  = makeAddr("sink");
        bot   = makeAddr("frontrunner");
    }

    function test_honest() public {
        console2.log("=== ACT 1: HONEST -- the owner moves the full amount ===");
        salm.mint(owner, 1000e18);
        salm.transfer(bob, 1000e18);
        console2.log("event said moved:", uint256(1000), "| bob actually received:", salm.balanceOf(bob) / 1e18);
        assertEq(salm.balanceOf(bob), 1000e18);
    }

    function test_trap() public {
        console2.log("=== ACT 2: TRAP -- a front-runner copies the move; the event LIES ===");
        salm.mint(bot, 1000e18);
        vm.prank(bot);
        salm.transfer(sink, 1000e18);     // event emits 1000...
        console2.log("Transfer event value : 1000  (what Etherscan / a naive bot sees)");
        console2.log("sink REAL balance    :", salm.balanceOf(sink) / 1e18, "  (only 1% actually moved)");
        assertEq(salm.balanceOf(sink), 10e18);
    }

    function test_fixed() public {
        console2.log("=== ACT 3: FIX -- verify the real balance delta ===");
        SafeReceiver r = new SafeReceiver();
        salm.mint(bot, 1000e18);
        vm.prank(bot);
        salm.approve(address(r), type(uint256).max);
        vm.prank(bot);
        vm.expectRevert(bytes("short transfer"));
        r.pull(ISalm(address(salm)), bot, 1000e18);   // the event said 1000; only 10 arrived -> revert
        console2.log("SafeReceiver reverts 'short transfer' -- the honeypot is caught, no loss");
    }
}
