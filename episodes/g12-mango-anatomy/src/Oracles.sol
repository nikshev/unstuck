// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MiniDEX} from "./MiniDEX.sol";

interface IOracle {
    function price() external view returns (uint256); // USDC per MNGO, 1e18
}

/// @title SpotOracle — THE VULNERABLE ORACLE.
/// Returns the DEX's instantaneous spot price. One big swap moves the pool, and
/// this oracle happily reports the manipulated number. This is the Mango Markets
/// mistake: value collateral at a price a single attacker can push around.
contract SpotOracle is IOracle {
    MiniDEX public dex;
    constructor(MiniDEX _dex) { dex = _dex; }
    function price() external view returns (uint256) {
        return dex.spotPrice();
    }
}

/// @title MedianOracle — THE FIX (a manipulation-resistant, TWAP-style oracle).
/// It stores price observations that can only be recorded once per MIN_PERIOD, and
/// reports the MEDIAN of the last few. A single-block pump adds at most one fresh
/// sample (usually none, because MIN_PERIOD hasn't elapsed), so it can't move the
/// median — exactly what a real TWAP/median oracle buys you.
contract MedianOracle is IOracle {
    MiniDEX public dex;
    uint256 public constant MIN_PERIOD = 1 hours;
    uint256 public constant N = 5;
    uint256[N] public obs;
    uint256 public count;
    uint256 public lastPoke;

    constructor(MiniDEX _dex) { dex = _dex; }

    /// Record one fresh spot sample — but never more than once per MIN_PERIOD.
    function poke() external {
        require(block.timestamp >= lastPoke + MIN_PERIOD || count == 0, "too soon");
        obs[count % N] = dex.spotPrice();
        count++;
        lastPoke = block.timestamp;
    }

    function price() external view returns (uint256) {
        uint256 n = count < N ? count : N;
        require(n > 0, "no data");
        uint256[] memory a = new uint256[](n);
        for (uint256 i; i < n; i++) a[i] = obs[i];
        // simple insertion sort, then take the median
        for (uint256 i = 1; i < n; i++) {
            uint256 v = a[i]; uint256 j = i;
            while (j > 0 && a[j - 1] > v) { a[j] = a[j - 1]; j--; }
            a[j] = v;
        }
        return a[n / 2];
    }
}
