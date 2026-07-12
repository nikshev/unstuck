// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Test, console2} from "forge-std/Test.sol";

interface IERC20 { function balanceOf(address) external view returns (uint256);
                   function approve(address, uint256) external returns (bool); }
interface IUniswapV2Router {
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin,
        address[] calldata path, address to, uint deadline) external returns (uint[] memory);
}

/// The same token, two prices: buy cheap on one DEX, sell dear on the other - atomically.
contract DexArbTest is Test {
    IERC20 constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IUniswapV2Router constant UNI   = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router constant SUSHI = IUniswapV2Router(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    address attacker = makeAddr("attacker");
    address whale    = makeAddr("whale");

    function setUp() public {
        // fork mainnet, fund the actors, set token approvals
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), 20_000_000);
        deal(address(USDC), attacker, 100_000e6);
        deal(address(WETH), whale,    500 ether);
        vm.startPrank(attacker); USDC.approve(address(UNI), type(uint).max);
                                 WETH.approve(address(SUSHI), type(uint).max); vm.stopPrank();
        vm.prank(whale); WETH.approve(address(UNI), type(uint).max);
    }

    function _swap(IUniswapV2Router r, IERC20 tin, IERC20 tout, uint amtIn, address who)
        internal returns (uint out) {
        // one swap through a router, returns the amount received
        address[] memory path = new address[](2);
        path[0] = address(tin); path[1] = address(tout);
        vm.prank(who);
        uint[] memory a = r.swapExactTokensForTokens(amtIn, 0, path, who, block.timestamp);
        out = a[a.length - 1];
    }

    function test_arbProfit() public {
        // create a price gap, then arbitrage it, assert the profit
        uint before = USDC.balanceOf(attacker);
        _swap(UNI, WETH, USDC, 300 ether, whale);          // whale dumps WETH on Uni -> cheap there
        uint bought = _swap(UNI, USDC, WETH, 50_000e6, attacker); // buy the cheap WETH on Uni
        _swap(SUSHI, WETH, USDC, bought, attacker);        // sell it dearer on Sushi
        uint profit = USDC.balanceOf(attacker) - before;
        console2.log("arb profit (USDC):", profit / 1e6);
        assertGt(USDC.balanceOf(attacker), before);        // ended with more USDC
    }

}
