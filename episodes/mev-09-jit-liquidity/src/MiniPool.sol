// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "./IERC20.sol";

/// @notice A minimal model of a concentrated-liquidity (Uniswap v3-style) pool, focused on the
/// one property JIT liquidity exploits: **swap fees are split among LPs in proportion to the
/// liquidity that is active AT THE MOMENT OF THE SWAP.**
///
/// In real v3 a searcher mints a *tight range* around the current price, which buys a huge
/// `liquidity` share for little capital, captures the fee of one big swap, then burns -- all in
/// the same block. Here we abstract the tick math: `addLiquidity(amount)` gives you `amount`
/// units of liquidity; the fee accounting (feeGrowth accumulator) is faithful to how v3 pays LPs.
contract MiniPool {
    IERC20 public immutable token0;   // asset bought out of the pool
    IERC20 public immutable token1;   // asset paid in; the 0.3% fee is taken here
    uint256 public reserve0;
    uint256 public reserve1;
    uint256 public totalLiquidity;
    uint256 public feeGrowthGlobal;   // token1 fees earned per unit of liquidity, scaled by 1e18

    struct Position { uint256 liquidity; uint256 feeGrowthLast; uint256 owed; }
    mapping(address => Position) public positions;

    constructor(IERC20 _t0, IERC20 _t1) { token0 = _t0; token1 = _t1; }

    // Deposit `amount` of BOTH tokens (lab runs at ~1:1); liquidity minted == amount.
    function addLiquidity(uint256 amount) external returns (uint256 liq) {
        _credit(msg.sender);
        token0.transferFrom(msg.sender, address(this), amount);
        token1.transferFrom(msg.sender, address(this), amount);
        reserve0 += amount;
        reserve1 += amount;
        positions[msg.sender].liquidity += amount;
        totalLiquidity += amount;
        return amount;
    }

    // Burn `liq` liquidity, taking back this position's proportional share of the reserves.
    function removeLiquidity(uint256 liq) external returns (uint256 a0, uint256 a1) {
        _credit(msg.sender);
        a0 = reserve0 * liq / totalLiquidity;
        a1 = reserve1 * liq / totalLiquidity;
        positions[msg.sender].liquidity -= liq;
        totalLiquidity -= liq;
        reserve0 -= a0;
        reserve1 -= a1;
        token0.transfer(msg.sender, a0);
        token1.transfer(msg.sender, a1);
    }

    // Swap token1 -> token0. A 0.3% fee is taken on the input and paid out to LPs pro-rata.
    function swap(uint256 amountIn) external returns (uint256 out) {
        require(totalLiquidity > 0, "no liquidity");
        uint256 fee = amountIn * 3 / 1000;
        uint256 inAfterFee = amountIn - fee;
        out = reserve0 * inAfterFee / (reserve1 + inAfterFee);   // constant product on the net input
        token1.transferFrom(msg.sender, address(this), amountIn);
        token0.transfer(msg.sender, out);
        reserve1 += inAfterFee;         // net input joins the tradable reserve
        reserve0 -= out;                // the fee stays as un-reserved token1 -> the LP fee pot
        feeGrowthGlobal += fee * 1e18 / totalLiquidity;
    }

    // Collect the token1 fees this position has earned.
    function collect() external returns (uint256 owed) {
        _credit(msg.sender);
        owed = positions[msg.sender].owed;
        positions[msg.sender].owed = 0;
        token1.transfer(msg.sender, owed);
    }

    // Bank fees accrued since this position last touched the pool.
    function _credit(address a) internal {
        Position storage p = positions[a];
        if (p.liquidity > 0) {
            p.owed += p.liquidity * (feeGrowthGlobal - p.feeGrowthLast) / 1e18;
        }
        p.feeGrowthLast = feeGrowthGlobal;
    }
}
