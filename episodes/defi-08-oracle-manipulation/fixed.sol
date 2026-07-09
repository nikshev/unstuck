// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ✅ FIXED — price comes from a trusted, manipulation-resistant feed (Chainlink / a TWAP).
// A momentary swap can't move it, so the over-borrow reverts and the pool is safe.

contract TrustedOracle {
    uint256 public immutable fixedPrice;        // a Chainlink feed, or a time-weighted average (TWAP)
    constructor(uint256 p) { fixedPrice = p; }
    function price() external view returns (uint256) {
        return fixedPrice;                       // <-- a single swap cannot move this
    }
}

contract LendingPool {
    TrustedOracle public oracle;
    uint256 public usdLiquidity;
    mapping(address => uint256) public collateral;
    mapping(address => uint256) public debt;
    constructor(TrustedOracle o, uint256 usd) { oracle = o; usdLiquidity = usd; }
    function depositCollateral(uint256 amt) external { collateral[msg.sender] += amt; }
    function borrow(uint256 usdAmount) external {
        uint256 maxDebt = collateral[msg.sender] * oracle.price() / 1e18;
        require(debt[msg.sender] + usdAmount <= maxDebt, "undercollateralized");
        require(usdAmount <= usdLiquidity, "not enough liquidity");
        debt[msg.sender] += usdAmount;
        usdLiquidity -= usdAmount;
    }
}
