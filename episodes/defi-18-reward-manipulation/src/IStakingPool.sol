// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Shared surface so ONE attacker contract can target both the vulnerable and fixed pools.
interface IStakingPool {
    function stake(uint256 amt) external;
    function unstake(uint256 amt) external;
    function claim() external returns (uint256);
}
