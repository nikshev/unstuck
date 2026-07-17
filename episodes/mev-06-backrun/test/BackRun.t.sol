// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
}
interface IUniV2Router {
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external returns (uint256[] memory);
}

/// Backrunning on a mainnet fork (block 20,000,000). A whale's large swap on Uniswap knocks its
/// WETH/USDC price out of line with SushiSwap. A backrunner does NOTHING to the whale — it just trades
/// right AFTER, buying the now-cheap WETH on Sushi and selling it on the now-expensive Uniswap, pocketing
/// the gap. Risk-free (the state change already happened) and victimless.
contract BackRunTest is Test {
    IERC20 constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IUniV2Router constant UNI   = IUniV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniV2Router constant SUSHI = IUniV2Router(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    address whale     = makeAddr("whale");
    address searcher  = makeAddr("searcher");

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), 20_000_000);
    }

    function _swap(IUniV2Router r, address who, address tin, address tout, uint256 amtIn) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = tin; path[1] = tout;
        vm.startPrank(who);
        IERC20(tin).approve(address(r), amtIn);
        uint256[] memory a = r.swapExactTokensForTokens(amtIn, 0, path, who, block.timestamp + 1);
        vm.stopPrank();
        return a[a.length - 1];
    }

    /// The arb profit available RIGHT NOW (buy WETH on Sushi with `usdcIn`, sell it on Uni), via snapshot.
    function _arbProfit(uint256 usdcIn) internal returns (int256) {
        uint256 snap = vm.snapshotState();
        deal(address(USDC), searcher, usdcIn);
        uint256 weth = _swap(SUSHI, searcher, address(USDC), address(WETH), usdcIn);
        uint256 back = _swap(UNI,   searcher, address(WETH), address(USDC), weth);
        vm.revertToState(snap);
        return int256(back) - int256(usdcIn);
    }

    function test_backrun() public {
        uint256 ARB = 500_000e6;    // searcher's arb size: $500,000

        // BEFORE the whale: the two pools are ~in line, so there's ~no free arb.
        emit log_named_decimal_int("arb profit BEFORE whale (USDC)", _arbProfit(ARB), 6);

        // The whale fires a big USDC->WETH buy on Uniswap, knocking its price out of line.
        deal(address(USDC), whale, 3_000_000e6);
        uint256 whaleWeth = _swap(UNI, whale, address(USDC), address(WETH), 3_000_000e6);
        emit log_named_decimal_uint("whale bought WETH on Uni", whaleWeth, 18);

        // BACKRUN: same block, right after. Buy the now-cheap WETH on Sushi, sell on the now-expensive Uni.
        deal(address(USDC), searcher, ARB);
        uint256 weth = _swap(SUSHI, searcher, address(USDC), address(WETH), ARB);
        uint256 back = _swap(UNI,   searcher, address(WETH), address(USDC), weth);
        int256 profit = int256(back) - int256(ARB);

        emit log_named_decimal_uint("searcher WETH bought on Sushi", weth, 18);
        emit log_named_decimal_uint("searcher USDC back from Uni", back, 6);
        emit log_named_decimal_int("=> backrun PROFIT (USDC)", profit, 6);

        assertGt(back, ARB, "backrun must be profitable after the whale's swap");
    }
}
