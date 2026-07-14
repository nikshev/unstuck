// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
interface IERC20 { function balanceOf(address) external view returns (uint256);
                   function transfer(address, uint256) external returns (bool);
                   function transferFrom(address, address, uint256) external returns (bool); }
// Minimal constant-product AMM pool with the usual 0.3% fee. One of three that form a price loop.
contract Pool {
    IERC20 public t0; IERC20 public t1; uint256 public r0; uint256 public r1;
    constructor(address a, address b) { t0 = IERC20(a); t1 = IERC20(b); }
    function sync() external { r0 = t0.balanceOf(address(this)); r1 = t1.balanceOf(address(this)); }
    function swap(address tokenIn, uint256 amtIn) external returns (uint256 out) {
        bool zeroIn = tokenIn == address(t0);
        (uint256 rIn, uint256 rOut) = zeroIn ? (r0, r1) : (r1, r0);
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amtIn);
        uint256 inAfterFee = amtIn * 997 / 1000;            // 0.3% fee
        out = rOut * inAfterFee / (rIn + inAfterFee);       // constant product x*y=k
        if (zeroIn) { r0 += amtIn; r1 -= out; t1.transfer(msg.sender, out); }
        else        { r1 += amtIn; r0 -= out; t0.transfer(msg.sender, out); }
    }
}
