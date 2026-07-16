# Promo — MEV #5: The Sandwich Attack

## X / Twitter thread
1/ The most common attack in MEV, on the REAL Uniswap pool.

A whale swaps $2,000,000 for ETH. A searcher wraps the trade front and back — and takes $67,000, risking almost nothing. Rebuilt on a mainnet fork 🧵

2/ Your swap sits in the public mempool for a moment before it's mined — in plain sight. A searcher sees a big one coming and buys the same token FIRST, with higher priority, so it's ordered ahead of you. The price ticks up.

3/ Now YOUR swap fills at that worse price — you get fewer tokens than you should. And immediately after you, the searcher SELLS what they just bought, into the pool your trade inflated.

Buy low → let you push it higher → sell high. Three txs, one block.

4/ On the real WETH/USDC pool (mainnet fork): the whale's $2M buy gets 485.68 WETH instead of the fair 503.47 — short ~18 WETH (~$68K). The searcher back-runs for +$66,889 USDC.

The whale's slippage IS the searcher's profit. ~98% of it.

5/ The fix is one number: a slippage limit (amountOutMin). Under the front-run the pool can't deliver your minimum, so your swap REVERTS instead of filling at a looted price. You fail safely and retry.

Stronger still: send it privately (Flashbots Protect / MEV Blocker).

6/ Full code + a Foundry test on a mainnet fork (with the ledger), the slippage-guard defense, and the same attack deployed to Sepolia — three real txs you can click on Etherscan:
https://github.com/nikshev/unstuck/tree/main/episodes/mev-05-sandwich

Full walkthrough on YouTube: @0xUnstuck

## Reddit (r/ethdev, r/defi) — educational
**Rebuilt the sandwich attack on a mainnet fork (front-run + victim + back-run, real Uni-v2 WETH/USDC), with the slippage-guard defense + a Sepolia/Etherscan proof**

A searcher brackets a whale's public swap: buy in front (price up), let the victim fill at the worse price, sell right after into the inflated pool. On the real WETH/USDC pool (fork @ block 20M), a $2M victim buy is short ~17.79 WETH (~$68K) and the searcher nets +$66,889 — about 98% of the victim's slippage.

Minimal Foundry reconstruction through the real router, plus `test_defended` showing a 0.5% `amountOutMin` reverts the sandwiched swap, and a Sepolia deploy verified as three txs on public Etherscan. Code + walkthrough in the link. Educational only — mainnet fork / testnet, no real funds.
