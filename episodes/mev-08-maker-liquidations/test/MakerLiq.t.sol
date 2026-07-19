// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import {Vat}                  from "../src/Vat.sol";
import {Vow}                  from "../src/Vow.sol";
import {Spotter, PriceFeed}   from "../src/Spotter.sol";
import {LinearDecrease}       from "../src/Abacus.sol";
import {Dog}                  from "../src/Dog.sol";
import {Clipper}              from "../src/Clipper.sol";

/// @title MakerDAO Liquidation 2.0 - Dutch-auction keeper lab
/// @notice Unsafe vault -> Dog.bark opens a Clipper auction above market ->
///         price decays -> a keeper `take`s below market and profits.
contract MakerLiqTest is Test {
    uint256 constant WAD   = 1e18;
    bytes32 constant ILK   = "ETH-A";
    uint256 constant START = 1_600_000_000; // a sane base timestamp

    // --- scenario constants (chosen so every number is exact) ---
    uint256 constant INK   = 100 * WAD;          // 100 ETH locked in the vault
    uint256 constant ART   = 100_000 * WAD;      // 100,000 DAI of debt
    uint256 constant PRICE = 1_400 * WAD;        // ETH market price = 1400 DAI
    uint256 constant MAT   = 15 * WAD / 10;      // 1.5   liquidation ratio (150%)
    uint256 constant CHOP  = 112 * WAD / 100;    // 1.12  liquidation penalty (+12%)
    uint256 constant BUF   = 12 * WAD / 10;      // 1.2   auction start multiplier
    uint256 constant TAU   = 3600;               // 1h linear decay to zero
    uint256 constant CHIP  = WAD / 1000;         // 0.1%  proportional bark tip

    Vat           vat;
    Vow           vow;
    Spotter       spotter;
    PriceFeed     pip;
    LinearDecrease calc;
    Dog           dog;
    Clipper       clip;

    address vault;   // the risky borrower (urn owner)
    address keeper;  // the liquidator / bidder

    function setUp() public {
        vm.warp(START);

        vault  = makeAddr("vault");
        keeper = makeAddr("keeper");

        vat     = new Vat();
        vow     = new Vow(address(vat));
        pip     = new PriceFeed();
        spotter = new Spotter(address(vat));
        calc    = new LinearDecrease();
        dog     = new Dog(address(vat));
        clip    = new Clipper(address(vat), address(spotter), ILK);

        // oracle + safety ratio
        pip.poke(PRICE);
        spotter.setPip(address(pip));
        spotter.file(ILK, MAT);

        // let the modules touch the Vat ledger
        vat.rely(address(dog));
        vat.rely(address(clip));
        vat.rely(address(spotter));

        // ilk + the unsafe urn
        vat.init(ILK, WAD, 0);        // rate = 1.0
        spotter.poke(ILK);            // spot = price / mat, pushed into the Vat
        vat.setUrn(ILK, vault, INK, ART);

        // Dog config
        dog.file("vow", address(vow));
        dog.file(ILK, "chop", CHOP);
        dog.file(ILK, "clip", address(clip));

        // Clipper config
        clip.file("dog",  address(dog));
        clip.file("vow",  address(vow));
        clip.file("calc", address(calc));
        clip.file("buf",  BUF);
        clip.file("chip", CHIP);
        calc.file("tau",  TAU);

        // fund the keeper with DAI to spend at the auction
        vat.mintDai(keeper, 200_000 * WAD);
    }

    function test_bark_then_take_keeperProfits() public {
        // ---------- 1. the vault is UNSAFE ----------
        (uint256 ink, uint256 art)     = vat.urns(ILK, vault);
        (, uint256 rate, )             = vat.ilks(ILK);
        uint256 debt   = art * rate / WAD;
        uint256 value  = ink * PRICE / WAD;      // market value of collateral
        uint256 needed = debt * MAT / WAD;       // value required to stay safe

        console2.log("================ VAULT (urn) BEFORE ================");
        console2.log("collateral ink  (ETH)      :", ink / WAD);
        console2.log("debt art        (DAI)      :", debt / WAD);
        console2.log("ETH price       (DAI/ETH)  :", PRICE / WAD);
        console2.log("collateral value(DAI)      :", value / WAD);
        console2.log("required value  (mat*debt) :", needed / WAD);
        console2.log("-> UNSAFE: value < required, liquidation allowed");
        assertLt(value, needed, "vault should be unsafe");

        // ---------- 2. DOG.BARK: open the Dutch auction ----------
        uint256 keeperDai0 = vat.dai(keeper);
        uint256 id = dog.bark(ILK, vault, keeper);
        uint256 tip = vat.dai(keeper) - keeperDai0; // bark incentive

        (uint256 tab, uint256 lot, , , uint256 top) = clip.sales(id);
        console2.log("================ DOG.BARK -> CLIPPER ==============");
        console2.log("auction id                 :", id);
        console2.log("tab to raise    (DAI)      :", tab / WAD);     // 112000 = debt*chop
        console2.log("lot for sale    (ETH)      :", lot / WAD);     // 100
        console2.log("top start price (DAI/ETH)  :", top / WAD);     // 1680 = price*buf (ABOVE market)
        console2.log("keeper bark tip (DAI)      :", tip / WAD);     // 112 = 0.1% of tab
        assertEq(tab, 112_000 * WAD);
        assertEq(lot, 100 * WAD);
        assertEq(top, 1_680 * WAD);

        // ---------- 3. the decay curve (top -> 0 over tau) ----------
        console2.log("================ PRICE DECAY (top -> 0) ==========");
        console2.log("t=   0s price (DAI/ETH)    :", calc.price(top,    0) / WAD); // 1680 above mkt
        console2.log("t= 600s price (DAI/ETH)    :", calc.price(top,  600) / WAD); // 1400 == market (break-even)
        console2.log("t=1200s price (DAI/ETH)    :", calc.price(top, 1200) / WAD); // 1120 BELOW market (profit)
        console2.log("market price  (DAI/ETH)    :", PRICE / WAD);

        // ---------- 4. TOO EARLY: taking now reverts on the slippage guard ----------
        // At t=0 the auction price (1680) is above the keeper's max (market=1400).
        vm.expectRevert("Clipper/too-expensive");
        clip.take(id, lot, PRICE, keeper);
        console2.log("================ TAKE @ t=0 (too early) ==========");
        console2.log("reverts: price 1680 > max 1400 -> keeper waits");

        // ---------- 5. WAIT for the price to decay below market ----------
        vm.warp(START + 1200); // 20 minutes later

        uint256 daiBefore = vat.dai(keeper);
        uint256 gemBefore = vat.gem(ILK, keeper);

        // keeper buys the whole lot; max = market price (never overpay vs market)
        clip.take(id, lot, PRICE, keeper);

        uint256 paid = daiBefore - vat.dai(keeper);
        uint256 got  = vat.gem(ILK, keeper) - gemBefore;
        uint256 takePrice = calc.price(top, 1200);
        uint256 mktValue  = got * PRICE / WAD;
        uint256 profit    = mktValue - paid;

        console2.log("================ TAKE @ t=1200 (profit) ==========");
        console2.log("take price      (DAI/ETH)  :", takePrice / WAD); // 1120
        console2.log("collateral got  (ETH)      :", got / WAD);       // 100
        console2.log("DAI paid        (DAI)      :", paid / WAD);      // 112000
        console2.log("market value    (DAI)      :", mktValue / WAD);  // 140000
        console2.log("KEEPER PROFIT   (DAI)      :", profit / WAD);    // 28000
        console2.log("(+ bark tip earlier)       :", tip / WAD);       // 112

        // exact-number checks
        assertEq(takePrice, 1_120 * WAD, "take price");
        assertEq(got,        100 * WAD,  "collateral received");
        assertEq(paid,   112_000 * WAD,  "DAI paid");
        assertEq(mktValue, 140_000 * WAD, "market value");
        assertEq(profit,  28_000 * WAD,  "keeper profit");
        assertGt(profit, 0, "keeper must profit");

        // ---------- 6. the system stays solvent ----------
        // The Vow raised `tab` (=112000) DAI. Its sin = the vault's debt (100000)
        // PLUS the freshly-minted keeper incentive (112), so net surplus =
        // penalty collected (12000) - keeper tip (112) = 11888.
        uint256 vowDai = vat.dai(address(vow));
        uint256 vowSin = vat.sin(address(vow));
        console2.log("================ SYSTEM (Vow) AFTER ==============");
        console2.log("vow DAI raised  (DAI)      :", vowDai / WAD);           // 112000
        console2.log("vow sin (debt+tip)(DAI)    :", vowSin / WAD);           // 100112
        console2.log("penalty collected(DAI)     :", (vowDai - debt) / WAD);  // 12000
        console2.log("net surplus buffer(DAI)    :", (vowDai - vowSin) / WAD);// 11888 = 12000 - 112
        assertEq(vowDai, 112_000 * WAD);
        assertEq(vowSin, debt + tip);        // 100000 + 112
        assertEq(vowDai - vowSin, 11_888 * WAD);
        assertGe(vowDai, vowSin, "auction must cover the debt");

        // auction fully cleared
        (,, address usr,,) = clip.sales(id);
        assertEq(usr, address(0), "auction should be finished");
    }

    /// @notice A well-collateralized vault cannot be liquidated: bark reverts.
    function test_bark_reverts_whenVaultSafe() public {
        pip.poke(2_000 * WAD); // ETH recovers to 2000 -> value 200000 >= 150000 required
        spotter.poke(ILK);
        vm.expectRevert("Dog/not-unsafe");
        dog.bark(ILK, vault, keeper);
    }
}
