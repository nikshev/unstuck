# Promo — MEV #7: Liquidations

## X / Twitter thread
1/ A DeFi loan just went underwater — and closing it pays $6,000. This is liquidation MEV: repay someone's bad debt, seize their collateral at a discount, keep the difference. Rebuilt in Foundry + proven on Sepolia 🧵

2/ DeFi loans are over-collateralized. A single number — the health factor — tracks the cushion. Post 100 WETH ($200k), borrow $150k → HF 1.07. Comfortable. Hold onto that number.

3/ Then ETH slips to $1,700. The collateral is worth less, so HF drops to 0.91 — below 1, the loan is underwater. Now anyone watching is allowed to step in.

4/ A liquidator repays $75k of the debt and, in return, seizes 47.6 WETH ($81k). The extra $6,000 is the liquidation bonus — the protocol's reward for closing a bad loan before it becomes a loss.

5/ There's no bug here. Liquidation is the mechanism working as designed; the bonus is just the fee that pays searchers. It's first-come-first-served, so bots race for it — one of the biggest categories of MEV.

6/ All three steps ran as real txs on Sepolia — borrow (HF 1.07), price drop (HF 0.91), liquidate (+$6k) — every field verifiable on Etherscan. Full code + line-by-line breakdown 👇
https://github.com/nikshev/unstuck/tree/main/episodes/mev-07-liquidations
