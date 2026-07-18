# MEV Explained — Ep 7: Liquidations

## 🎬 Watch

🔴 **New episode** — [Subscribe](https://www.youtube.com/channel/UC32d5uV5MEC1oMqVaVbQPNA?sub_confirmation=1) to catch it when it drops.

DeFi loans are over-collateralized, and a single number — the **health factor** — says how safe each one is.
Post **100 WETH ($200k)**, borrow **$150k**, and your health factor sits at **1.07**. Then WETH slips to
**$1,700**: the health factor drops to **0.91**, the loan is underwater, and **anyone** can repay part of the
debt and seize the collateral **at a discount**. A liquidator repays **$75k**, takes **47.6 WETH ($81k)**,
and pockets **+$6,000** — the 8% liquidation bonus. It's a first-come-first-served MEV race, and it's what
keeps lending protocols solvent.

## The idea in one test

`test/Liquidation.t.sol` builds a minimal over-collateralized `LendingPool` (an 80% liquidation threshold, an
8% bonus) with `healthFactor` and `liquidate`, then runs the whole sequence:

- **`test_liquidation`** — the borrower posts 100 WETH and borrows $150k → **HF 1.067** at $2,000. WETH drops
  to $1,700 → **HF 0.907**, underwater. A liquidator repays **$75k**, seizes **47.6 WETH ($81k)** →
  **+$6,000**, the liquidation bonus.

> There's no bug to fix here. Liquidation is the mechanism doing its job — the bonus is simply the fee that
> pays searchers to close bad loans before they become protocol losses.

## Run it yourself

Requires [Foundry](https://getfoundry.sh).

```bash
forge install foundry-rs/forge-std   # first time only
forge test -vv
```

You'll see `[PASS] test_liquidation` — the health factor **1.067 → 0.907** as the price falls, then the
liquidator repaying **$75k** and seizing **$81k** for a **+$6,000** bonus.

## Proven on Sepolia (public Etherscan)

`script/LiquidationSepolia.s.sol` deploys the lending pool and runs the sequence as **three real
transactions** on the Sepolia testnet, through a Chainstack node:

1. **Borrow** — [`0x4dc0…74d11a`](https://sepolia.etherscan.io/tx/0x4dc031868f456252a1bbef58ab3e45c6de40044c9ad3599de517ba695b74d11a) — post 100 WETH, borrow 150k (**HF 1.07**).
2. **Price drop** — [`0xe356…1462a4`](https://sepolia.etherscan.io/tx/0xe35660393a9ac736539be0ff279e7b8e916621b0f45ef5e6a89fd760461462a4) — the oracle moves **$2,000 → $1,700** (**HF 0.91**, underwater).
3. **Liquidate** — [`0x71de…0e6d5ce`](https://sepolia.etherscan.io/tx/0x71de1ca4fd4a6ccece9167483e92bb2351928ec291cdf8b22d8bc85ac0e6d5ce) — repay 75k, seize 47.6 WETH → **+$6,000**.

Pool `0x7e13…8945` · three consecutive blocks.

## ⚠️ Educational only

Everything runs locally / on a testnet — no real users or funds. Don't use any of this to harm others.
