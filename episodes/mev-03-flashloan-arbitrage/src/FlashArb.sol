// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {console2} from "forge-std/console2.sol"; // lets the contract print its balances as it runs

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
}
// Uniswap / Sushi V2 router: one swap along a token path.
interface IUniswapV2Router {
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin,
        address[] calldata path, address to, uint deadline) external returns (uint[] memory);
}
// Aave v3 flash loan: borrow, get a callback, repay in the SAME transaction.
interface IAavePool {
    function flashLoanSimple(address receiver, address asset, uint256 amount,
        bytes calldata params, uint16 referralCode) external;
}

/// Flash-loan arbitrageur: borrow USDC from Aave, buy WETH cheap on Uniswap, sell it dear on
/// SushiSwap, repay the loan + fee, keep the rest. ZERO starting capital.
contract FlashArb {
    IERC20 constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // wrapped ETH
    IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // USD stablecoin
    IUniswapV2Router constant UNI   = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Uniswap v2
    IUniswapV2Router constant SUSHI = IUniswapV2Router(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F); // SushiSwap
    IAavePool constant AAVE = IAavePool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2); // the flash-loan source
    /// Kick off: borrow `amount` USDC from Aave — it calls executeOperation below.
    function startArb(uint256 amount) external {
        AAVE.flashLoanSimple(address(this), address(USDC), amount, "", 0); // borrow, no collateral
    }
    /// Aave's callback: we hold the borrowed USDC. Arb it, printing our balance at every step, then repay.
    function executeOperation(address, uint256 amount, uint256 premium, address, bytes calldata)
        external returns (bool)
    {
        console2.log("1. flash-borrowed USDC :", USDC.balanceOf(address(this)) / 1e6);   // Aave just sent it
        uint256 weth = _swap(UNI, USDC, WETH, amount);   // buy cheap WETH on Uniswap
        console2.log("2. bought WETH (x1e-3) :", WETH.balanceOf(address(this)) / 1e15);  // spent all the USDC
        _swap(SUSHI, WETH, USDC, weth);                  // sell dear WETH on SushiSwap
        console2.log("3. sold WETH, hold USDC:", USDC.balanceOf(address(this)) / 1e6);   // back to USDC, more of it
        console2.log("4. owe Aave (loan+fee) :", (amount + premium) / 1e6);              // must repay this much
        USDC.approve(address(AAVE), amount + premium);   // let Aave pull back loan + fee
        console2.log("5. PROFIT kept (USDC)  :", (USDC.balanceOf(address(this)) - amount - premium) / 1e6);
        return true;                                     // leftover USDC here = pure profit
    }
    /// One swap through a router (Uniswap or Sushi); returns how many output tokens we got.
    function _swap(IUniswapV2Router r, IERC20 tin, IERC20 tout, uint256 amtIn)
        internal returns (uint256 out)
    {
        tin.approve(address(r), amtIn);                  // let the router spend our tokens
        address[] memory path = new address[](2);        // route: [tokenIn, tokenOut]
        path[0] = address(tin); path[1] = address(tout);
        uint256[] memory a = r.swapExactTokensForTokens(amtIn, 0, path, address(this), block.timestamp);
        out = a[a.length - 1];                           // amount of tokenOut we received
    }
}

