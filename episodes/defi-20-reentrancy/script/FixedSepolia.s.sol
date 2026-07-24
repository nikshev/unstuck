// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {VaultFixed} from "../src/VaultFixed.sol";
import {Attacker, IVault} from "../src/Attacker.sol";
contract FixedSepolia is Script {
    function run() external {
        vm.startBroadcast();
        VaultFixed v = new VaultFixed();
        v.deposit{value: 0.05 ether}();
        Attacker atk = new Attacker(IVault(address(v)));
        vm.stopBroadcast();
        console2.log("VAULT=%s", address(v));
        console2.log("ATTACKER=%s", address(atk));
    }
}
