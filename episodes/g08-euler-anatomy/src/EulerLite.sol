// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./MockToken.sol";

/// A tiny lending market that reproduces the MECHANISM of the Euler Finance hack (2023-03-13, ~$197M):
/// a `donateToReserves` that lets you give away your own collateral WITHOUT re-checking your health —
/// so you can push YOUR OWN account underwater on demand and then self-liquidate for the bonus, which
/// is paid out of the pool + the reserves you just donated. Faithful to the flaw, simplified for teaching.
contract EulerLite {
    MockToken public asset;
    uint256 public constant CF = 90;      // collateral factor (%)
    uint256 public constant BONUS = 20;   // liquidation bonus (%)
    uint256 public priceBps = 10_000;     // collateral price (100% = 10000); a market move changes it
    mapping(address=>uint256) public collateral;
    mapping(address=>uint256) public debt;
    uint256 public reserves;

    constructor(MockToken a){ asset = a; }

    function setPrice(uint256 bps) external { priceBps = bps; }   // demo-only: simulate a market move

    function deposit(uint256 amt) external {
        asset.transferFrom(msg.sender, address(this), amt);
        collateral[msg.sender] += amt;
    }
    function withdraw(uint256 amt) external {
        collateral[msg.sender] -= amt;
        require(healthy(msg.sender), "unhealthy");
        asset.transfer(msg.sender, amt);
    }
    function borrow(uint256 amt) external {
        debt[msg.sender] += amt;
        require(healthy(msg.sender), "unhealthy");
        asset.transfer(msg.sender, amt);
    }
    function repay(uint256 amt) external {
        asset.transferFrom(msg.sender, address(this), amt);
        debt[msg.sender] -= amt;
    }
    function healthy(address u) public view returns(bool){
        return collateral[u] * priceBps / 10_000 * CF / 100 >= debt[u];
    }

    // ── THE BUG ── give collateral to reserves, but DON'T re-check the caller's health.
    function donateToReserves(uint256 amt) external {
        collateral[msg.sender] -= amt;
        reserves += amt;
        // MISSING: require(healthy(msg.sender), "unhealthy");
    }

    function liquidate(address violator, uint256 repayAmt) external {
        require(!healthy(violator), "violator is healthy");
        asset.transferFrom(msg.sender, address(this), repayAmt);
        debt[violator] -= repayAmt;
        uint256 seize = repayAmt * (100 + BONUS) / 100;      // collateral seized incl. bonus
        uint256 fromColl = seize <= collateral[violator] ? seize : collateral[violator];
        collateral[violator] -= fromColl;
        reserves -= (seize - fromColl);                      // bonus shortfall paid from reserves
        collateral[msg.sender] += seize;                     // liquidator receives it as collateral
    }
}
