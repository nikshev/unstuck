// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Script, console2} from "forge-std/Script.sol";
import {GovToken, Governance, GovernanceFixed, Attacker} from "../src/FlashGov.sol";

contract DeploySepolia is Script {
    function run() external {
        uint256 pk = vm.envUint("PK");
        address me = vm.addr(pk);
        vm.startBroadcast(pk);
        GovToken token = new GovToken(400_000e18, 600_000e18, me);
        Governance gov = new Governance{value: 0.02 ether}(token);
        Attacker attacker = new Attacker(token, address(gov));
        GovernanceFixed govF = new GovernanceFixed{value: 0.02 ether}(token);
        Attacker attackerF = new Attacker(token, address(govF));
        vm.stopBroadcast();
        console2.log("TOKEN", address(token));
        console2.log("GOV", address(gov));
        console2.log("ATTACKER", address(attacker));
        console2.log("GOVFIXED", address(govF));
        console2.log("ATTACKERF", address(attackerF));
    }
}
