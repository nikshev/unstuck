// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Test, console2} from "forge-std/Test.sol";
import {FlashArb, IERC20, IUniswapV2Router} from "../src/FlashArb.sol";

contract FlashArbTest is Test {
    IERC20 WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IUniswapV2Router UNI = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address whale = makeAddr("whale");
    FlashArb arb;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), 20_000_000); // real mainnet, pinned block
        deal(address(WETH), whale, 500 ether);                         // give a whale some WETH
        vm.startPrank(whale);
        WETH.approve(address(UNI), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(WETH); path[1] = address(USDC);
        UNI.swapExactTokensForTokens(300 ether, 0, path, whale, block.timestamp); // dump WETH -> cheap on Uni
        vm.stopPrank();
        arb = new FlashArb();                                          // deploy our arb, holding nothing
    }

    function test_flashArb() public {
        console2.log("--- flash-loan arbitrage, ZERO capital ---");
        console2.log("our USDC balance at start:", USDC.balanceOf(address(arb)) / 1e6); // 0
        assertEq(USDC.balanceOf(address(arb)), 0);          // prove we start with ZERO capital
        arb.startArb(50_000e6);                             // borrow 50k USDC, arb it, repay — one tx
        uint256 profit = USDC.balanceOf(address(arb));      // whatever's left is pure profit
        console2.log("our USDC balance at end:  ", profit / 1e6);
        assertGt(profit, 0);                                // we made money from nothing
    }
}
