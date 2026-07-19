// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

import {Vat}                  from "../src/Vat.sol";
import {Vow}                  from "../src/Vow.sol";
import {Spotter, PriceFeed}   from "../src/Spotter.sol";
import {LinearDecrease}       from "../src/Abacus.sol";
import {Dog}                  from "../src/Dog.sol";
import {Clipper}              from "../src/Clipper.sol";

// -----------------------------------------------------------------------------
// Proven on Sepolia (public Etherscan) — bark opens the auction ABOVE market, the
// Dutch price decays, then the keeper `take`s BELOW market. Two real transactions:
//   Dog     0x21e28ac700f07ec7e9ee54548ea22e72d4e5dd34
//   Clipper 0x7b0e8976c6f924a71af5dd3036e308e69235d0b0
//   keeper  0x26201027D4Fd2908c9fd6Dac8Ef4c0cc1f11cd92
//   1. Dog.bark — open the Clipper auction; top starts at 1,680 DAI/ETH (above the
//      1,400 market), tab 112,000 DAI on the 100 ETH lot:
//      https://sepolia.etherscan.io/tx/0xcb14afee96b5f5e7f2faff10addb716fb2fd3884e5b256daf40a1d4851a46165
//   2. take — after the price decays below market, buy the 100 ETH lot for 107,520
//      DAI (~1,075 DAI/ETH, worth 140,000 at market) -> +32,480 DAI keeper profit:
//      https://sepolia.etherscan.io/tx/0x2ec34f94240c008f3f50d324f741765550e561adaa5e8a2ef18dc073e806dc25
// -----------------------------------------------------------------------------

// Maker Liquidations 2.0 — Sepolia deploy for the capstone. Replicates the test setUp (an UNSAFE
// vault ready to liquidate) but with a SHORT tau so the Dutch price decays below market within a
// couple of minutes of REAL time. The deployer plays the keeper. bark + take are done afterward
// with cast (separate, clickable txs). Logs every address for the orchestrator.
contract MakerLiqSepolia is Script {
    uint256 constant WAD   = 1e18;
    bytes32 constant ILK   = "ETH-A";
    uint256 constant INK   = 100 * WAD;          // 100 ETH locked
    uint256 constant ART   = 100_000 * WAD;      // 100,000 DAI debt
    uint256 constant PRICE = 1_400 * WAD;        // ETH market = 1400 (unsafe: 140k < 150k needed)
    uint256 constant MAT   = 15 * WAD / 10;      // 1.5
    uint256 constant CHOP  = 112 * WAD / 100;    // 1.12
    uint256 constant BUF   = 12 * WAD / 10;      // 1.2  -> top = 1680 (above market)
    uint256 constant TAU   = 600;                // SHORT: 10 min to zero (below market by ~t=100s)
    uint256 constant CHIP  = WAD / 1000;         // 0.1% bark tip
    address constant VAULT = address(0x000000000000000000000000000000000000b0b0); // dummy borrower

    function run() external {
        address keeper = msg.sender;             // the deployer plays the keeper
        vm.startBroadcast();

        Vat            vat     = new Vat();
        Vow            vow     = new Vow(address(vat));
        PriceFeed      pip     = new PriceFeed();
        Spotter        spotter = new Spotter(address(vat));
        LinearDecrease calc    = new LinearDecrease();
        Dog            dog     = new Dog(address(vat));
        Clipper        clip    = new Clipper(address(vat), address(spotter), ILK);

        pip.poke(PRICE);
        spotter.setPip(address(pip));
        spotter.file(ILK, MAT);

        vat.rely(address(dog));
        vat.rely(address(clip));
        vat.rely(address(spotter));

        vat.init(ILK, WAD, 0);
        spotter.poke(ILK);
        vat.setUrn(ILK, VAULT, INK, ART);

        dog.file("vow", address(vow));
        dog.file(ILK, "chop", CHOP);
        dog.file(ILK, "clip", address(clip));

        clip.file("dog",  address(dog));
        clip.file("vow",  address(vow));
        clip.file("calc", address(calc));
        clip.file("buf",  BUF);
        clip.file("chip", CHIP);
        calc.file("tau",  TAU);

        vat.mintDai(keeper, 200_000 * WAD);

        vm.stopBroadcast();

        console2.log("VAT=%s",     address(vat));
        console2.log("VOW=%s",     address(vow));
        console2.log("SPOTTER=%s", address(spotter));
        console2.log("CALC=%s",    address(calc));
        console2.log("DOG=%s",     address(dog));
        console2.log("CLIP=%s",    address(clip));
        console2.log("VAULT=%s",   VAULT);
        console2.log("KEEPER=%s",  keeper);
    }
}
