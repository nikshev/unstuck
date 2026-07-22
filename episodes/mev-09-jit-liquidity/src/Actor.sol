// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "./IERC20.sol";

interface IMiniPool {
    function addLiquidity(uint256 amt) external returns (uint256);
    function removeLiquidity(uint256 liq) external returns (uint256, uint256);
    function swap(uint256 amountIn) external returns (uint256);
    function collect() external returns (uint256);
}

/// @notice A stand-in account for the Sepolia capstone, so the passive LP, the JIT searcher and the
/// trader are DISTINCT on-chain addresses (positions are keyed by msg.sender). Each action is its own
/// clickable transaction.
contract Actor {
    IMiniPool public pool;
    constructor(IMiniPool _pool, IERC20 t0, IERC20 t1) {
        pool = _pool;
        t0.approve(address(_pool), type(uint256).max);
        t1.approve(address(_pool), type(uint256).max);
    }
    function add(uint256 a) external { pool.addLiquidity(a); }
    function remove(uint256 a) external { pool.removeLiquidity(a); }
    function swap(uint256 a) external { pool.swap(a); }
    function collect() external returns (uint256) { return pool.collect(); }
}
