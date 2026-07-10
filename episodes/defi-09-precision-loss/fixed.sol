// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ✅ FIXED — reject any deposit that would mint ZERO shares (the precision robbery).
// Production-grade also: seed 'dead shares' on first deposit, or use a virtual shares+assets
// offset (OpenZeppelin ERC-4626 decimals offset). The one-line guard already closes the drain.
contract VaultFixed {
    uint256 public totalShares;
    uint256 public totalAssets;
    mapping(address => uint256) public shares;
    function depositFor(uint256 assets, address to) public returns (uint256 s) {
        s = totalShares == 0 ? assets : assets * totalShares / totalAssets;
        require(s > 0, "zero shares");                                         // <-- the fix
        shares[to] += s; totalShares += s; totalAssets += assets;
    }
    function donate(uint256 assets) external { totalAssets += assets; }
    function redeem(uint256 s, address to) external returns (uint256 assets) {
        assets = s * totalAssets / totalShares;
        shares[to] -= s; totalShares -= s; totalAssets -= assets;
    }
}
