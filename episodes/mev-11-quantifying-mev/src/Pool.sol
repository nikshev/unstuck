// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {IERC20} from "./IERC20.sol";

/// @notice A minimal constant-product AMM (WETH <-> TOKEN), the thing a searcher sandwiches.
/// price of TOKEN rises as you buy it; a 0.3% fee is taken on the input.
contract Pool {
    IERC20 public immutable weth;
    IERC20 public immutable token;
    uint256 public rWeth;   // WETH reserve
    uint256 public rToken;  // TOKEN reserve
    constructor(IERC20 _w, IERC20 _t) { weth = _w; token = _t; }

    function init(uint256 w, uint256 t) external {
        weth.transferFrom(msg.sender, address(this), w);
        token.transferFrom(msg.sender, address(this), t);
        rWeth += w; rToken += t;
    }
    // spend WETH, receive TOKEN (price of TOKEN goes UP)
    function buyToken(uint256 wethIn) external returns (uint256 out) {
        weth.transferFrom(msg.sender, address(this), wethIn);
        uint256 inAfterFee = wethIn * 997 / 1000;
        out = rToken * inAfterFee / (rWeth + inAfterFee);
        rWeth += wethIn; rToken -= out;
        token.transfer(msg.sender, out);
    }
    // spend TOKEN, receive WETH
    function sellToken(uint256 tokenIn) external returns (uint256 out) {
        token.transferFrom(msg.sender, address(this), tokenIn);
        uint256 inAfterFee = tokenIn * 997 / 1000;
        out = rWeth * inAfterFee / (rToken + inAfterFee);
        rToken += tokenIn; rWeth -= out;
        weth.transfer(msg.sender, out);
    }
}
