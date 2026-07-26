// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./Underlying.sol";

// A minimal zkLend-style lending market. Deposits mint zTokens scaled by a
// `lendingAccumulator` (RAY = 1e27). The bug: withdraw() burns
// floor(amount * RAY / acc) zTokens -- ROUNDED DOWN. Once the accumulator is
// inflated on an empty market, a withdrawal smaller than one zToken's worth
// burns ZERO zTokens, so the attacker withdraws underlying for free.
contract Market {
    uint256 constant RAY = 1e27;
    Underlying public immutable asset;
    uint256 public lendingAccumulator = RAY;        // 1.0 to start
    mapping(address=>uint256) public zBalance;      // "raw" scaled balance

    constructor(Underlying a){ asset = a; }

    function deposit(uint256 amount) external {
        asset.transferFrom(msg.sender, address(this), amount);
        uint256 minted = amount * RAY / lendingAccumulator;   // floor
        zBalance[msg.sender] += minted;
    }
    function withdraw(uint256 amount) external {
        uint256 burned = amount * RAY / lendingAccumulator;   // BUG: floor (should ceil)
        zBalance[msg.sender] -= burned;                       // underflow-guards real balance
        asset.transfer(msg.sender, amount);
    }
    // The Feb-2025 attacker inflated the accumulator via flash-loan-driven
    // interest on an (almost) empty market. We model that jump directly.
    function _inflateAccumulator(uint256 newAcc) external { lendingAccumulator = newAcc; }
    function underlyingBalance() external view returns(uint256){ return asset.balanceOf(address(this)); }
}
