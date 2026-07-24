// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {Vault} from "../src/Vault.sol";
import {Attacker, IVault} from "../src/Attacker.sol";
contract AttackSepolia is Script {
    function run() external {
        vm.startBroadcast();
        Vault v = new Vault();
        v.deposit{value: 0.05 ether}();   // honest pool (5 x 0.01)
        Attacker atk = new Attacker(IVault(address(v)));
        vm.stopBroadcast();
        console2.log("VAULT=%s", address(v));
        console2.log("ATTACKER=%s", address(atk));
    }
}
