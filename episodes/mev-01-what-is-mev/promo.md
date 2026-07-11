# Promo — MEV Ep 1: What Is MEV?

## X / Twitter thread
1/ MEV — Maximal Extractable Value — is bots earning billions on Ethereum just by choosing the ORDER of transactions. New series: we explain it from scratch and reproduce every attack locally. Ep 1 👇

2/ Why is order worth money? One tiny Foundry test proves it: a one-shot prize where the FIRST caller wins everything. `forge test` → the searcher ordered first takes it all, the one behind gets nothing.

3/ But who decides the order? Gas. Send two txs — 5 gwei vs 120 gwei — to a local fork and the 120-gwei one lands at position 0. That's a Priority Gas Auction, the original MEV, from the 2019 "Flash Boys 2.0" paper.

4/ Everything runs locally: Anvil (a private Ethereum) + Foundry + Otterscan (a local explorer). Fully reproducible, code in the repo. Ahead: arbitrage, sandwiches, liquidations, JIT, MEV-Boost.

▶️ [video link]  ·  code: https://github.com/nikshev/unstuck/tree/main/episodes/mev-01-what-is-mev

## Reddit (r/ethdev, r/ethereum, r/defi) — educational
**What Is MEV? Proving why transaction order is worth money (with a runnable Foundry test)**

Started a beginner-friendly series on MEV, reproduced entirely on a local fork. Ep 1 explains MEV from the Flash Boys 2.0 paper and proves the core idea with a tiny Foundry test (first caller wins the prize; whoever is ordered first takes the value). Then it shows a Priority Gas Auction on a local chain in Otterscan — the 120-gwei tx lands at position 0. All code + `forge test` in the repo. Feedback welcome.

## One-liner (Community post / caption)
New series 🧵 What is MEV? Bots quietly reorder your transactions for profit. We prove why order = money with a Foundry test you can run yourself, then watch a gas auction on a local chain. Ep 1 out now.

## Meme angle
"the mempool is a public place" → bots watching every pending tx (dark-forest vibe).
