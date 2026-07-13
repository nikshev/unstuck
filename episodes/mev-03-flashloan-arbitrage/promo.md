# Promo — MEV #3: Flash-Loan Arbitrage

## X / Twitter
1/ You can arbitrage two exchanges with $0 of your own money.

Borrow millions with a flash loan, do the trade, pay it back — all in ONE transaction. If it doesn't profit, the whole thing reverts. 🧵

2/ The trade: WETH is cheaper on Uniswap than Sushi. So:
→ flash-borrow USDC from Aave
→ buy cheap WETH on Uni
→ sell it dear on Sushi
→ repay Aave + fee
→ keep the difference

3/ We built it as a Foundry test on a mainnet fork. The contract starts with ZERO USDC and ends with a real $1,306 profit.

4/ Why it matters: no capital needed → anyone can play → the mempool is a war zone of bots. Code:
https://github.com/nikshev/unstuck/tree/main/episodes/mev-03-flashloan-arbitrage

## Reddit (r/ethdev, r/defi)
**Reproduced a flash-loan arbitrage in Foundry — $1,306 profit, zero starting capital**
FlashArb borrows USDC from Aave, buys cheap WETH on Uniswap, sells on Sushi, repays the loan + fee, keeps the rest — one atomic tx on a mainnet fork. Educational, fork only. Code inside.
