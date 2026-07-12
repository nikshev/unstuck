// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Test, console2} from "forge-std/Test.sol";
import {GovToken, Governance, GovernanceFixed, Attacker} from "../src/FlashGov.sol";

contract FlashGovTest is Test {
    GovToken token; Governance gov; Attacker attacker;
    address honest = makeAddr("honest");
    function setUp() public {
        token = new GovToken(400_000e18, 600_000e18, honest);
        gov = new Governance{value: 100 ether}(token);
        attacker = new Attacker(token, address(gov));
    }
    function test_drain() public {
        assertEq(address(gov).balance, 100 ether);
        attacker.pwn(600_000e18);
        console2.log("drained to attacker (ETH):", address(attacker).balance / 1e18);
        assertEq(address(attacker).balance, 100 ether);
    }
    function test_fixed_blocksIt() public {
        GovernanceFixed g = new GovernanceFixed{value: 100 ether}(token);
        Attacker a = new Attacker(token, address(g));
        vm.expectRevert();
        a.pwn(600_000e18);
        assertEq(address(g).balance, 100 ether);
    }
}
