// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {MockERC20} from "../src/MockERC20.sol";
import {IERC20} from "../src/IERC20.sol";
import {Pool} from "../src/Pool.sol";
import {Searcher, IPool} from "../src/Searcher.sol";

/// Quantifying MEV — reproduce a sandwich, then MEASURE the searcher's profit.
/// `forge test -vvvv --match-test test_sandwich` prints the full call TRACE: read the WETH the
/// searcher sends in (front-run) vs the WETH it takes out (back-run) -> that difference is the MEV.
contract SandwichTest is Test {
    MockERC20 weth; MockERC20 token; Pool pool; Searcher s;
    address victim;

    function setUp() public {
        weth = new MockERC20("Wrapped Ether", "WETH");
        token = new MockERC20("Token", "TKN");
        pool = new Pool(IERC20(address(weth)), IERC20(address(token)));
        weth.mint(address(this), 130e18); token.mint(address(this), 100_000e18);
        weth.approve(address(pool), type(uint256).max);
        token.approve(address(pool), type(uint256).max);
        pool.init(100e18, 100_000e18);                 // 100 WETH : 100,000 TKN
        s = new Searcher(IPool(address(pool)), IERC20(address(weth)), IERC20(address(token)));
        weth.mint(address(s), 10e18);                  // searcher funded with 10 WETH
        victim = address(this);
    }

    function test_sandwich() public {
        console2.log("=== QUANTIFY A SANDWICH ===");
        uint256 before = weth.balanceOf(address(s));
        console2.log("searcher WETH before (x0.01):", before / 1e16);
        s.frontrun(10e18);                              // 1. buy TKN just before the victim
        pool.buyToken(20e18);                           // 2. the VICTIM's big swap (worse price)
        s.backrun();                                    // 3. sell the TKN just after
        uint256 aft = weth.balanceOf(address(s));
        console2.log("searcher WETH after  (x0.01):", aft / 1e16);
        console2.log("searcher PROFIT (x0.01 WETH):", (aft - before) / 1e16, "= 3.66 WETH from the victims slippage");
        console2.log("-> the MEV = WETH taken out (back-run) - WETH put in (front-run)");
        assertGt(aft, before);                          // the sandwich is profitable
    }
}
