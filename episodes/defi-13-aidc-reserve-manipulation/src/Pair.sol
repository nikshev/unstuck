// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
interface IERC20ish { function balanceOf(address) external view returns(uint256); function transfer(address,uint256) external returns(bool); function transferFrom(address,address,uint256) external returns(bool); }
// Minimal constant-product AMM pair (WBNB <-> AIDC), with sync() like a real Uniswap V2 pair.
contract Pair {
    IERC20ish public aidc; IERC20ish public wbnb; uint256 public rAidc; uint256 public rWbnb;
    constructor(address a,address w){ aidc=IERC20ish(a); wbnb=IERC20ish(w); }
    // sync sets reserves to the pair's ACTUAL token balances (this is what the exploit abuses)
    function sync() external { rAidc = aidc.balanceOf(address(this)); rWbnb = wbnb.balanceOf(address(this)); }
    function swapAidcForWbnb(uint256 aidcIn) external returns(uint256 out){
        aidc.transferFrom(msg.sender, address(this), aidcIn);
        out = (rWbnb * aidcIn) / (rAidc + aidcIn);   // xy = k
        rAidc += aidcIn; rWbnb -= out;
        wbnb.transfer(msg.sender, out);
    }
}
