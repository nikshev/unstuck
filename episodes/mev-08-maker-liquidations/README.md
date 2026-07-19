# MEV — Ep 08: Maker Liquidations 2.0 (Dutch-Auction Keeper Profit)

## 🎬 Watch

🔴 **New episode** — [Subscribe](https://www.youtube.com/channel/UC32d5uV5MEC1oMqVaVbQPNA?sub_confirmation=1) to catch it when it drops.

When a MakerDAO vault falls below its safety ratio, anyone can **liquidate** it. Liquidations 2.0 does it as
a **Dutch auction**: `Dog.bark` seizes the collateral and opens a `Clipper` auction that **starts above
market** and **decays over time**. A keeper just **waits** — the instant the falling price drops below the
real market price, they `take` the collateral cheap and pocket the spread. No flash loan, no exploit: the
protocol is *paying* keepers to keep it solvent, and a patient keeper turns that into MEV.

## The idea in one test

`test/MakerLiq.t.sol` builds a minimal Maker core (`Vat`, `Spotter`, `Dog`, `Clipper`, `LinearDecrease`,
`Vow`) with an **unsafe** vault: **100 ETH** collateral, **100,000 DAI** debt, ETH at **1,400** → collateral
worth 140,000 < the 150,000 the 1.5 ratio requires.

- **`test_bark_then_take_keeperProfits`** — `Dog.bark` opens the auction with `top = 1,680` DAI/ETH (price ×
  the 1.2 buffer, **above** the 1,400 market) on a **112,000 DAI** tab. Taking at t=0 reverts
  (`too-expensive`). Wait ~20 min and the linear decay drops the price to **1,120**; the keeper `take`s all
  **100 ETH** for **112,000 DAI** — worth **140,000** at market → **+28,000 DAI profit**, and the system's
  `Vow` books an **11,888 DAI** surplus buffer.
- **`test_bark_reverts_whenVaultSafe`** — nudge ETH back to 2,000 (collateral worth 200,000 ≥ 150,000) and
  `Dog.bark` reverts `not-unsafe`: healthy vaults can't be liquidated.

> The keeper's edge is **time**, not capital. The auction opens deliberately high so honest bidders reveal
> demand; if nobody bites, the price falls until someone profits. Watch the curve, take the instant it
> crosses market.

## Run it yourself

Requires [Foundry](https://getfoundry.sh).

```bash
forge install foundry-rs/forge-std   # first time only
forge test -vv
```

You'll see `[PASS] test_bark_then_take_keeperProfits` (top **1,680** → decays to **1,120**, keeper buys 100
ETH for 112,000 DAI worth 140,000 → **+28,000**) and `[PASS] test_bark_reverts_whenVaultSafe`.

## Proven on Sepolia (public Etherscan)

`script/MakerLiqSepolia.s.sol` deploys the same setup with a **short `tau`** so the Dutch price decays below
market within minutes of real time; the deployer plays the keeper and `bark` + `take` run as **two real
transactions**, through a Chainstack node:

1. **Bark** — [`0xcb14…46165`](https://sepolia.etherscan.io/tx/0xcb14afee96b5f5e7f2faff10addb716fb2fd3884e5b256daf40a1d4851a46165) — open the Clipper auction; `top` starts at **1,680** DAI/ETH (above the 1,400 market).
2. **Take** — [`0x2ec3…06dc25`](https://sepolia.etherscan.io/tx/0x2ec34f94240c008f3f50d324f741765550e561adaa5e8a2ef18dc073e806dc25) — after the price decays below market, buy **100 ETH** for **107,520 DAI** (~1,075 DAI/ETH, worth 140,000) → **+32,480 DAI** keeper profit.

Dog `0x21e28ac700f07ec7e9ee54548ea22e72d4e5dd34` · Clipper `0x7b0e8976c6f924a71af5dd3036e308e69235d0b0` · keeper `0x26201027D4Fd2908c9fd6Dac8Ef4c0cc1f11cd92`.

## ⚠️ Educational only

Everything runs on a local chain / testnet — no real users or funds. Don't use any of this to harm others.
