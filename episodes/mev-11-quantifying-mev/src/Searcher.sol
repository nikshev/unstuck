// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {IERC20} from "./IERC20.sol";

interface IPool {
    function buyToken(uint256 wethIn) external returns (uint256);
    function sellToken(uint256 tokenIn) external returns (uint256);
}

/// @notice The sandwich searcher. frontrun() buys TOKEN just before the victim (pushing the price
/// up); backrun() sells ALL its TOKEN just after (into the price the victim inflated) for a profit.
/// Read `weth.balanceOf(searcher)` before/after to measure the profit -- that's "quantifying" the MEV.
contract Searcher {
    IPool  public immutable pool;
    IERC20 public immutable weth;
    IERC20 public immutable token;
    constructor(IPool _p, IERC20 _w, IERC20 _t) {
        pool = _p; weth = _w; token = _t;
        _w.approve(address(_p), type(uint256).max);
        _t.approve(address(_p), type(uint256).max);
    }
    function frontrun(uint256 wethIn) external { pool.buyToken(wethIn); }
    function backrun() external { pool.sellToken(token.balanceOf(address(this))); }
}
