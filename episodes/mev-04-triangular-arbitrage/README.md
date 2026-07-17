# MEV Explained — Ep 4: Triangular / Multi-Hop Arbitrage

## 🎬 Watch

📅 **Premieres Jul 18, 2026.** [Subscribe on YouTube](https://www.youtube.com/channel/UC32d5uV5MEC1oMqVaVbQPNA) to catch it.

Arbitrage isn't only "buy low on one exchange, sell high on another." It can be a **loop**: send one
token through three pools — WETH → USDC → DAI → WETH — and come out with **more WETH than you started**,
all in one transaction, because the three prices don't multiply back to one. The profit lives in the
cycle, not in any single pair. And there's a catch every searcher learns the hard way: **size it wrong
and your own price impact eats the edge.**

## The idea in one test
`test/TriPools.t.sol` builds a controlled 3-pool lab:
- `MockToken` — a minimal 18-decimals token.
- `Pool` — a minimal constant-product AMM (`x*y=k`) with the usual 0.3% fee and a `sync()`.
- Three pools wired into a ring: **WETH/USDC (1:3000)**, **USDC/DAI (1:1.05 — mispriced)**, **DAI/WETH (1:3000)**. That one dislocation opens the loop.

`test_arb` sends **10 WETH** around the ring and asserts it comes back as more: `10 → 29,614 USDC → 30,820 DAI → 10.138 WETH` (**+0.138 WETH**). `test_tooBig` sends **100 WETH** through the same pools and it returns **82.4 WETH** (**−17.6**) — the loop's own slippage overwhelms the ~5% edge. There is an optimal size.

> A real triangular arb needs three deep pools. On a live Ethereum fork only the WETH pairs are deep
> enough (USDC/DAI, WBTC/USDC on Uniswap v2 are too thin), so this uses a clean, self-contained lab —
> the mechanism and the lesson are identical.

## Run it yourself
Requires [Foundry](https://getfoundry.sh).

```bash
forge install foundry-rs/forge-std   # first time only
forge test -vv
```

`test_arb` prints the per-hop ledger of a profitable loop; `test_tooBig` prints the same loop losing to
its own price impact.

## Key idea
- Arbitrage can be a **loop** through 3+ pools, not just A↔B across two venues.
- You profit when the cycle's exchange rates multiply to **more than 1** (after fees).
- A single mispriced pool is enough to open the loop.
- **Size is everything:** too much through the loop and your own slippage wipes out the edge — searchers optimize the amount, not just the path.

## Sources
- Flash Boys 2.0 (Daian et al., 2019): https://arxiv.org/abs/1904.05234
- Uniswap v2 constant-product & pricing: https://docs.uniswap.org/contracts/v2/concepts/protocol-overview/how-uniswap-works
- MEV overview: https://ethereum.org/en/developers/docs/mev/
- Foundry: https://getfoundry.sh
