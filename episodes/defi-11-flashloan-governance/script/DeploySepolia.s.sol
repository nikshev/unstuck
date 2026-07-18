// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Script, console2} from "forge-std/Script.sol";

// -- Proven on Sepolia (public Etherscan) via a Chainstack node -------------------------------
//   gov (vuln)  0xa39b10bed8222c9f9950953a38e894669e445ba7
//   gov (fixed) 0x47756f046cbae38aa8571399d22789640e289635
//   1 DRAIN  https://sepolia.etherscan.io/tx/0x09008bca8ba11460037bc721bbbc4a64e88de6330a1a20481b12bf95faa0cac9  (Success, treasury drained)
//   2 FIXED  https://sepolia.etherscan.io/tx/0xb3c5b8e249ecb1e8175dd34b1c899f633761a30afe2693b462a256fef540e7ea  (Fail, reverts 'timelock: wait a block')
// --------------------------------------------------------------------------------------------

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
