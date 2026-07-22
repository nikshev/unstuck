// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "./IERC20.sol";

/// @notice VULNERABLE staking pool.
/// Your reward is proportional to your share of the pool *right now*, measured at claim time.
/// Nothing ties the payout to HOW LONG you staked -- so a one-block whale scoops the whole pot.
contract StakingPool {
    IERC20 public immutable stakeToken;   // an LP token
    IERC20 public immutable rewardToken;  // the reward being handed out
    uint256 public rewardReserve;         // the pot still available to claim
    mapping(address => uint256) public staked;
    uint256 public totalStaked;

    constructor(IERC20 _stake, IERC20 _reward) { stakeToken = _stake; rewardToken = _reward; }

    function fund(uint256 amt) external {
        rewardToken.transferFrom(msg.sender, address(this), amt);
        rewardReserve += amt;
    }

    function stake(uint256 amt) external {
        stakeToken.transferFrom(msg.sender, address(this), amt);
        staked[msg.sender] += amt;
        totalStaked += amt;
    }

    function unstake(uint256 amt) external {
        staked[msg.sender] -= amt;
        totalStaked -= amt;
        stakeToken.transfer(msg.sender, amt);
    }

    // BUG: payout = your CURRENT share of the pot. Stake huge, claim, unstake -- all in one tx.
    function claim() external returns (uint256 reward) {
        require(totalStaked > 0, "empty");
        reward = rewardReserve * staked[msg.sender] / totalStaked;
        rewardReserve -= reward;
        rewardToken.transfer(msg.sender, reward);
    }
}
