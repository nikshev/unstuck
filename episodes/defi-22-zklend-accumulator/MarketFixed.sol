// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./Underlying.sol";
contract MarketFixed {
    uint256 constant RAY = 1e27;
    Underlying public immutable asset;
    uint256 public lendingAccumulator = RAY;
    mapping(address=>uint256) public zBalance;
    constructor(Underlying a){ asset = a; }
    function deposit(uint256 amount) external {
        asset.transferFrom(msg.sender, address(this), amount);
        zBalance[msg.sender] += amount * RAY / lendingAccumulator;      // mint floor (favours pool)
    }
    function withdraw(uint256 amount) external {
        // FIX: round the burned zTokens UP so a withdrawal can never cost 0 zTokens
        uint256 burned = (amount * RAY + lendingAccumulator - 1) / lendingAccumulator;  // ceil
        zBalance[msg.sender] -= burned;
        asset.transfer(msg.sender, amount);
    }
    function _inflateAccumulator(uint256 newAcc) external { lendingAccumulator = newAcc; }
    function underlyingBalance() external view returns(uint256){ return asset.balanceOf(address(this)); }
}
