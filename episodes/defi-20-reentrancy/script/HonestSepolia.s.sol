// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {Vault} from "../src/Vault.sol";
contract HonestSepolia is Script {
    function run() external {
        vm.startBroadcast();
        Vault v = new Vault();
        v.deposit{value: 0.03 ether}();   // the deployer stands in for an honest depositor
        vm.stopBroadcast();
        console2.log("VAULT=%s", address(v));
    }
}
