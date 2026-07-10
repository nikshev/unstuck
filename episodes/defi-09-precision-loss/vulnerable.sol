// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ❌ VULNERABLE — a share vault that mints shares PROPORTIONALLY and rounds DOWN.
// On an almost-empty vault an attacker inflates the share price (via donate) so a victim's
// deposit rounds down to ZERO shares — the vault keeps the money and mints nothing.
contract Vault {
    uint256 public totalShares;
    uint256 public totalAssets;
    mapping(address => uint256) public shares;
    function depositFor(uint256 assets, address to) public returns (uint256 s) {
        s = totalShares == 0 ? assets : assets * totalShares / totalAssets;   // rounds DOWN -> can be 0
        shares[to] += s; totalShares += s; totalAssets += assets;
    }
    function donate(uint256 assets) external { totalAssets += assets; }        // raises price, mints NO shares
    function redeem(uint256 s, address to) external returns (uint256 assets) {
        assets = s * totalAssets / totalShares;
        shares[to] -= s; totalShares -= s; totalAssets -= assets;
    }
}
