// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "./IERC20.sol";

/// @notice A DEFENDED concentrated-liquidity pool: swap fees are split by liquidity x TIME-IN-POOL
/// (liquidity-seconds), not by instantaneous liquidity. A JIT position that lives for a single block
/// has ~0 liquidity-seconds, so it earns ~none of the fee — while a passive LP that has provided
/// liquidity for a long time keeps it. (A demonstrable design; the primary real-world defense is
/// private orderflow, so the searcher can't see the swap coming.)
contract MiniPoolTW {
    IERC20 public immutable token0;
    IERC20 public immutable token1;
    uint256 public reserve0;
    uint256 public reserve1;
    uint256 public totalLiquidity;
    uint256 public totalLiqSeconds;   // sum over time of totalLiquidity * dt
    uint256 public lastUpdate;
    uint256 public feePot;            // token1 fees collected, distributed by liquidity-seconds

    struct Position { uint256 liquidity; uint256 liqSeconds; uint256 last; }
    mapping(address => Position) public positions;

    constructor(IERC20 _t0, IERC20 _t1) { token0 = _t0; token1 = _t1; lastUpdate = block.timestamp; }

    function _tick() internal {
        totalLiqSeconds += totalLiquidity * (block.timestamp - lastUpdate);
        lastUpdate = block.timestamp;
    }
    function _tickPos(address a) internal {
        Position storage p = positions[a];
        if (p.last == 0) p.last = block.timestamp;
        p.liqSeconds += p.liquidity * (block.timestamp - p.last);
        p.last = block.timestamp;
    }

    function addLiquidity(uint256 amt) external returns (uint256) {
        _tick(); _tickPos(msg.sender);
        token0.transferFrom(msg.sender, address(this), amt);
        token1.transferFrom(msg.sender, address(this), amt);
        reserve0 += amt; reserve1 += amt;
        positions[msg.sender].liquidity += amt;
        totalLiquidity += amt;
        return amt;
    }

    function removeLiquidity(uint256 liq) external returns (uint256 a0, uint256 a1) {
        _tick(); _tickPos(msg.sender);
        a0 = reserve0 * liq / totalLiquidity;
        a1 = reserve1 * liq / totalLiquidity;
        positions[msg.sender].liquidity -= liq;
        totalLiquidity -= liq;
        reserve0 -= a0; reserve1 -= a1;
        token0.transfer(msg.sender, a0);
        token1.transfer(msg.sender, a1);
    }

    function swap(uint256 amountIn) external returns (uint256 out) {
        _tick();
        uint256 fee = amountIn * 3 / 1000;
        uint256 inAfterFee = amountIn - fee;
        out = reserve0 * inAfterFee / (reserve1 + inAfterFee);
        token1.transferFrom(msg.sender, address(this), amountIn);
        token0.transfer(msg.sender, out);
        reserve1 += inAfterFee;
        reserve0 -= out;
        feePot += fee;                 // the fee waits in the pot, to be split by liquidity-seconds
    }

    function collect() external returns (uint256 owed) {
        _tick(); _tickPos(msg.sender);
        if (totalLiqSeconds > 0) owed = feePot * positions[msg.sender].liqSeconds / totalLiqSeconds;
        feePot -= owed;
        totalLiqSeconds -= positions[msg.sender].liqSeconds;   // consume this position's weight
        positions[msg.sender].liqSeconds = 0;
        token1.transfer(msg.sender, owed);
    }
}
