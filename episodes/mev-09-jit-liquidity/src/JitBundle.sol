// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {IERC20} from "./IERC20.sol";

interface IPool {
    function addLiquidity(uint256) external returns (uint256);
    function removeLiquidity(uint256) external returns (uint256, uint256);
    function swap(uint256) external returns (uint256);
    function collect() external returns (uint256);
}

/// @notice A one-block JIT "sandwich" bundle. In a SINGLE atomic transaction it mints a huge
/// position, lets the swap execute, collects the fee, and burns -- so its time-in-pool is 0.
/// On a plain (instantaneous-share) pool this scoops ~all of the swap fee. On a time-weighted
/// pool the same move earns ~0, because 0 seconds in the pool == 0 liquidity-seconds.
/// After run(), read `jitFee()` for the exact fee the JIT actually collected.
contract JitBundle {
    IPool  public immutable pool;
    IERC20 public immutable t0;
    IERC20 public immutable t1;
    uint256 public jitFee;      // fee collected on the last run() -- read this on-chain
    constructor(IPool _pool, IERC20 _t0, IERC20 _t1) {
        pool = _pool; t0 = _t0; t1 = _t1;
        _t0.approve(address(_pool), type(uint256).max);
        _t1.approve(address(_pool), type(uint256).max);
    }
    function run(uint256 jliq, uint256 swapAmt) external returns (uint256) {
        pool.addLiquidity(jliq);       // mint, just before the swap
        pool.swap(swapAmt);            // the swap that pays the 0.3% fee (same block)
        jitFee = pool.collect();       // scoop the fee it was owed
        pool.removeLiquidity(jliq);    // burn, just after -- 0 seconds in the pool
        return jitFee;
    }
}
