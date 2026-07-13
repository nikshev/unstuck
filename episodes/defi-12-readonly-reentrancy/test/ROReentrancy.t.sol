// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Test, console2} from "forge-std/Test.sol";
import {IVault, Vault, VaultFixed, Seller, Attacker} from "../src/ROReentrancy.sol";

contract ROReentrancyTest is Test {
    address provider = makeAddr("provider");

    function test_drain() public {
        Vault vault = new Vault();
        Seller seller = new Seller(IVault(address(vault)));
        vm.deal(provider, 100 ether);
        vm.prank(provider); vault.deposit{value: 100 ether}();          // 100 ETH, 100 shares, price 1.0
        vm.prank(provider); vault.transferShares(address(seller), 50 ether); // seller has 50 shares to sell
        Attacker attacker = new Attacker(IVault(address(vault)), seller);
        vm.deal(address(this), 100 ether);
        attacker.pwn{value: 100 ether}();                               // attack with 100 ETH
        console2.log("attacker in (ETH):  100");
        console2.log("attacker out (ETH):", address(attacker).balance / 1e18);
        assertGt(address(attacker).balance, 100 ether);                 // profited via the stale price
    }

    function test_fixed_blocksIt() public {
        VaultFixed vault = new VaultFixed();
        Seller seller = new Seller(IVault(address(vault)));
        vm.deal(provider, 100 ether);
        vm.prank(provider); vault.deposit{value: 100 ether}();
        vm.prank(provider); vault.transferShares(address(seller), 50 ether);
        Attacker attacker = new Attacker(IVault(address(vault)), seller);
        vm.deal(address(this), 100 ether);
        vm.expectRevert();                                              // pricePerShare reverts mid-withdraw
        attacker.pwn{value: 100 ether}();
    }
}
