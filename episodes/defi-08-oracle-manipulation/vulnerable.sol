// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ❌ VULNERABLE — the lender prices collateral with an AMM's live SPOT price.
// A big (flash-loaned) swap moves that spot price within ONE transaction, so an attacker can make
// cheap collateral look extremely valuable and borrow the whole pool against it.

interface IAMM { function spotPrice() external view returns (uint256); }

contract SpotOracle {
    IAMM public amm;
    constructor(IAMM a) { amm = a; }
    function price() external view returns (uint256) {
        return amm.spotPrice();                 // <-- the bug: a live, tradeable price
    }
}

contract LendingPool {
    SpotOracle public oracle;
    uint256 public usdLiquidity;
    mapping(address => uint256) public collateral;
    mapping(address => uint256) public debt;
    constructor(SpotOracle o, uint256 usd) { oracle = o; usdLiquidity = usd; }
    function depositCollateral(uint256 amt) external { collateral[msg.sender] += amt; }
    function borrow(uint256 usdAmount) external {
        uint256 maxDebt = collateral[msg.sender] * oracle.price() / 1e18;   // value from a manipulable oracle
        require(debt[msg.sender] + usdAmount <= maxDebt, "undercollateralized");
        require(usdAmount <= usdLiquidity, "not enough liquidity");
        debt[msg.sender] += usdAmount;
        usdLiquidity -= usdAmount;
    }
}
