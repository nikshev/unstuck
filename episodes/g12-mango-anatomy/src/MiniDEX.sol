// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MockToken} from "./MockToken.sol";

/// @title MiniDEX — a constant-product (x*y=k) pool for MNGO/USDC.
/// Its instantaneous "spot price" is just the ratio of reserves — which means a
/// single large swap moves it a lot. That is the exact property an attacker abuses
/// when a lending market trusts this spot price as its oracle.
contract MiniDEX {
    MockToken public mngo;
    MockToken public usdc;
    uint256 public resMngo;   // MNGO reserve
    uint256 public resUsdc;   // USDC reserve

    constructor(MockToken _mngo, MockToken _usdc) {
        mngo = _mngo;
        usdc = _usdc;
    }

    /// Seed the pool with starting liquidity (tokens must be sent/minted first).
    function sync() external {
        resMngo = mngo.balanceOf(address(this));
        resUsdc = usdc.balanceOf(address(this));
    }

    /// USDC per MNGO, scaled 1e18. reserveUSDC / reserveMNGO.
    function spotPrice() public view returns (uint256) {
        require(resMngo > 0, "no liq");
        return resUsdc * 1e18 / resMngo;
    }

    /// Swap `usdcIn` USDC for MNGO (no fee, for a clean demo). Pumps the MNGO price.
    function swapUsdcForMngo(uint256 usdcIn) external returns (uint256 mngoOut) {
        usdc.transferFrom(msg.sender, address(this), usdcIn);
        uint256 k = resMngo * resUsdc;
        uint256 newUsdc = resUsdc + usdcIn;
        uint256 newMngo = k / newUsdc;
        mngoOut = resMngo - newMngo;
        resUsdc = newUsdc;
        resMngo = newMngo;
        mngo.transfer(msg.sender, mngoOut);
    }
}
