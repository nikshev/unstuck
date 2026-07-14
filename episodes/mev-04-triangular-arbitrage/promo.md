# Promo — MEV #4: Triangular / Multi-Hop Arbitrage

## X / Twitter thread
1/ Arbitrage isn't just "buy low here, sell high there."

Send one token on a lap through THREE pools — WETH → USDC → DAI → WETH — and it can come back as more of itself. The profit lives in the loop 🧵

2/ Why it works: if you multiply the three exchange rates and get exactly 1, you end where you started (minus fees). But if the prices are even slightly inconsistent, the product tops 1 — and one lap of the loop pays.

3/ In the lab: three constant-product pools. Two priced fairly (WETH/USDC and DAI/WETH at 3000), one mispriced — USDC/DAI hands out 1.05 DAI per USDC. That crack is the whole opportunity.

4/ Send 10 WETH around: 10 → 29,614 USDC → 30,820 DAI → 10.138 WETH. A small, clean profit, out of nothing but a price inconsistency. One atomic transaction.

5/ The catch every searcher learns the hard way: send 100 WETH through the SAME loop and it comes back as 82. Your own trade moves the pools against you every hop — slippage eats the edge. There's an optimal size.

6/ Full code + a Foundry test that prints the per-hop ledger for both the profitable loop and the too-big one:
https://github.com/nikshev/unstuck/tree/main/episodes/mev-04-triangular-arbitrage

Full walkthrough on YouTube: @0xUnstuck

## Reddit (r/ethdev, r/defi) — educational
**Triangular arbitrage from scratch in Foundry (per-hop ledger + why size, not just path, decides the profit)**

A loop through three constant-product pools (WETH→USDC→DAI→WETH) nets more WETH than it starts with when the three prices don't multiply back to 1 — here one pool is mispriced 1 USDC→1.05 DAI. The test shows a 10-WETH loop profiting and a 100-WETH loop losing to its own slippage, so you can see the optimal-size tradeoff. Self-contained lab (real Uni-v2 non-WETH pools are too thin for a clean fork demo). Code + walkthrough in the link. Educational only.
