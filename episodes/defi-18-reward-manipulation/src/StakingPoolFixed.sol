// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "./IERC20.sol";

/// @notice FIXED pool (Synthetix-style, time-weighted).
/// Rewards accrue per staked-token *per second*. A stake and claim in the SAME block span
/// zero seconds, so a flash-loaned whale earns exactly nothing. Only real duration pays.
contract StakingPoolFixed {
    IERC20 public immutable stakeToken;
    IERC20 public immutable rewardToken;
    uint256 public rewardRate;              // reward tokens per second (total, split across stakers)
    uint256 public rewardReserve;
    uint256 public rewardPerTokenStored;
    uint256 public lastUpdate;
    mapping(address => uint256) public userPaid;   // rewardPerToken already credited to a user
    mapping(address => uint256) public rewards;    // reward owed, banked at each interaction
    mapping(address => uint256) public staked;
    uint256 public totalStaked;

    constructor(IERC20 _stake, IERC20 _reward) { stakeToken = _stake; rewardToken = _reward; }

    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) return rewardPerTokenStored;
        return rewardPerTokenStored + (block.timestamp - lastUpdate) * rewardRate * 1e18 / totalStaked;
    }

    function earned(address a) public view returns (uint256) {
        return staked[a] * (rewardPerToken() - userPaid[a]) / 1e18 + rewards[a];
    }

    modifier update(address a) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdate = block.timestamp;
        rewards[a] = earned(a);
        userPaid[a] = rewardPerTokenStored;
        _;
    }

    function fund(uint256 amt, uint256 rate) external {
        rewardToken.transferFrom(msg.sender, address(this), amt);
        rewardReserve += amt;
        rewardRate = rate;
        lastUpdate = block.timestamp;
    }

    function stake(uint256 amt) external update(msg.sender) {
        stakeToken.transferFrom(msg.sender, address(this), amt);
        staked[msg.sender] += amt;
        totalStaked += amt;
    }

    function unstake(uint256 amt) external update(msg.sender) {
        staked[msg.sender] -= amt;
        totalStaked -= amt;
        stakeToken.transfer(msg.sender, amt);
    }

    function claim() external update(msg.sender) returns (uint256 reward) {
        reward = rewards[msg.sender];
        if (reward > rewardReserve) reward = rewardReserve;
        rewards[msg.sender] -= reward;
        rewardReserve -= reward;
        rewardToken.transfer(msg.sender, reward);
    }
}
