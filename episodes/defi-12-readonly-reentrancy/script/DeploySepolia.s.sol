// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Script, console2} from "forge-std/Script.sol";
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
