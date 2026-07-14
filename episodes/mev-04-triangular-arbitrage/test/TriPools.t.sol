// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Test, console2} from "forge-std/Test.sol";
import {MockToken} from "../src/MockToken.sol";
import {Pool} from "../src/Pool.sol";

/// Triangular arbitrage in a controlled 3-pool world: one token in, a LOOP through three pools,
/// more of the SAME token out — because the three prices don't multiply back to 1.
contract TriPoolsTest is Test {
    MockToken weth; MockToken usdc; MockToken dai;
    Pool ab; // WETH/USDC @ 1 WETH = 3000 USDC
    Pool bc; // USDC/DAI  @ 1 USDC = 1.05 DAI  <- the mispriced pool
    Pool ca; // DAI/WETH  @ 1 WETH = 3000 DAI
    address bot = makeAddr("bot");

    function setUp() public {
        weth = new MockToken("WETH", 18);
        usdc = new MockToken("USDC", 18);
        dai  = new MockToken("DAI", 18);
        ab = new Pool(address(weth), address(usdc)); weth.mint(address(ab), 1_000 ether);     usdc.mint(address(ab), 3_000_000 ether); ab.sync();
        bc = new Pool(address(usdc), address(dai));  usdc.mint(address(bc), 5_000_000 ether);  dai.mint(address(bc), 5_250_000 ether);  bc.sync();
        ca = new Pool(address(dai), address(weth));  dai.mint(address(ca), 3_000_000 ether);  weth.mint(address(ca), 1_000 ether);     ca.sync();
    }

    function _loop(uint amtIn) internal returns (int profit) {
        weth.mint(bot, amtIn);
        vm.startPrank(bot);
        weth.approve(address(ab), amtIn);
        uint u = ab.swap(address(weth), amtIn);       // hop 1: WETH -> USDC
        usdc.approve(address(bc), u);
        uint d = bc.swap(address(usdc), u);           // hop 2: USDC -> DAI  (the 1.05 pool)
        dai.approve(address(ca), d);
        uint w = ca.swap(address(dai), d);            // hop 3: DAI -> WETH
        vm.stopPrank();
        profit = int(w) - int(amtIn);
        console2.log("== triangular loop: WETH -> USDC -> DAI -> WETH ==");
        console2.log("start WETH  (x1e-3):", amtIn / 1e15);
        console2.log("1 WETH->USDC (USDC):", u / 1e18);
        console2.log("2 USDC->DAI  (DAI) :", d / 1e18);
        console2.log("3 DAI->WETH  (x1e-3):", w / 1e15);
        console2.log("profit WETH  (x1e-3):");
        console2.logInt(profit / 1e15);
    }

    // Right size: the ~5% dislocation beats the fees + slippage -> profit.
    function test_arb() public { int p = _loop(10 ether); assertGt(p, 0); }

    // Too big: the loop's own price impact overwhelms the edge -> loss (optimal size matters).
    function test_tooBig() public { int p = _loop(100 ether); assertLt(p, 0); }
}
