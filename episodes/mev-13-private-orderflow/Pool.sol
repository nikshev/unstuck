// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
// Minimal constant-product AMM (WETH <-> TOKEN). Price moves with every trade;
// that price impact is exactly what a sandwich preys on.
contract Pool {
    uint256 public rWeth;    // WETH reserve
    uint256 public rToken;   // TOKEN reserve
    constructor(uint256 w,uint256 t){ rWeth=w; rToken=t; }
    // buy TOKEN with WETH
    function buy(uint256 wethIn) external returns(uint256 out){
        uint256 inAfter = wethIn * 997 / 1000;             // 0.3% fee
        out = rToken * inAfter / (rWeth + inAfter);
        rWeth += wethIn; rToken -= out;
    }
    // sell TOKEN for WETH
    function sell(uint256 tokenIn) external returns(uint256 out){
        uint256 inAfter = tokenIn * 997 / 1000;
        out = rWeth * inAfter / (rToken + inAfter);
        rToken += tokenIn; rWeth -= out;
    }
    function price() external view returns(uint256){ return rWeth * 1e18 / rToken; }
}
