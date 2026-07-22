// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "./IERC20.sol";
import {IStakingPool} from "./IStakingPool.sol";

/// @notice A stand-in staker for the Sepolia capstone, so Alice and Bob are DISTINCT on-chain
/// addresses (positions key by msg.sender). Each action is its own clickable transaction.
contract StakeActor {
    IStakingPool public pool;
    constructor(IStakingPool _pool, IERC20 lp) {
        pool = _pool;
        lp.approve(address(_pool), type(uint256).max);
    }
    function stake(uint256 a) external { pool.stake(a); }
    function unstake(uint256 a) external { pool.unstake(a); }
    function claim() external returns (uint256) { return pool.claim(); }
}
