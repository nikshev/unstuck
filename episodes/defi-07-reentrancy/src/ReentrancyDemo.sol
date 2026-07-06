// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// A simple ETH vault: deposit ETH, then withdraw your balance.
// ❌ VULNERABLE — sends the ETH BEFORE zeroing the balance.
contract VaultVulnerable {
    mapping(address => uint256) public balance;
    function deposit() external payable { balance[msg.sender] += msg.value; }
    function seed() external payable {}                  // pooled funds from earlier depositors
    function withdraw() external {
        uint256 amt = balance[msg.sender];
        require(amt > 0, "no balance");
        (bool ok, ) = msg.sender.call{value: amt}("");   // interaction FIRST (the bug)
        require(ok, "send failed");
        balance[msg.sender] = 0;                          // effect LAST — too late
    }
}

// ✅ FIXED — checks-effects-interactions: zero the balance BEFORE the call.
contract VaultFixed {
    mapping(address => uint256) public balance;
    function deposit() external payable { balance[msg.sender] += msg.value; }
    function seed() external payable {}
    function withdraw() external {
        uint256 amt = balance[msg.sender];
        require(amt > 0, "no balance");
        balance[msg.sender] = 0;                          // effect FIRST (the fix)
        (bool ok, ) = msg.sender.call{value: amt}("");    // interaction LAST
        require(ok, "send failed");
    }
}

// ▶ CLICK-TO-RUN demo of the OLD (vulnerable) path.
//   Deploy with a Value of 11 ether, then click: vaultBalance -> attack -> vaultBalance / attackerLoot.
contract Demo_OLD_Vulnerable {
    VaultVulnerable public vault;
    constructor() payable {
        vault = new VaultVulnerable();
        vault.seed{value: 3 ether}();       // other users' pooled deposits sit in the vault
    }
    function attack() external {
        vault.deposit{value: 1 ether}();     // the attacker deposits just 1 ETH
        vault.withdraw();                    // ...and re-enters to drain everything
    }
    receive() external payable {
        if (address(vault).balance >= 1 ether) vault.withdraw();   // re-enter while the balance isn't zeroed
    }
    function sweep(address to) external { (bool ok,) = payable(to).call{value: address(this).balance}(""); require(ok, "sweep failed"); }
    function vaultBalance()  external view returns (uint256) { return address(vault).balance / 1e18; }
    function attackerLoot()  external view returns (uint256) { return address(this).balance  / 1e18; }
}

// ▶ CLICK-TO-RUN demo of the NEW (fixed) path. Same attack -> reverts.
contract Demo_NEW_Fixed {
    VaultFixed public vault;
    constructor() payable {
        vault = new VaultFixed();
        vault.seed{value: 3 ether}();
    }
    function attack() external {
        vault.deposit{value: 1 ether}();
        vault.withdraw();                    // re-entry now reverts (balance already zeroed)
    }
    receive() external payable {
        if (address(vault).balance >= 1 ether) vault.withdraw();
    }
    function sweep(address to) external { (bool ok,) = payable(to).call{value: address(this).balance}(""); require(ok, "sweep failed"); }
    function vaultBalance()  external view returns (uint256) { return address(vault).balance / 1e18; }
    function attackerLoot()  external view returns (uint256) { return address(this).balance  / 1e18; }
}
