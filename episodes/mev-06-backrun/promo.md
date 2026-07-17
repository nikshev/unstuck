# Promo — MEV #6: Backrunning

## X / Twitter thread
1/ The sandwich has a gentler cousin that hurts no one — and it's MOST of what MEV actually is. It's called backrunning. Rebuilt on the real Uniswap + Sushi pools, proven on Sepolia 🧵

2/ Every big swap moves a pool's price. A whale buys $3M of WETH on Uniswap → WETH gets pricier there. But not on Sushi. For a moment the SAME token has two different prices.

3/ That gap is free money: buy the cheap WETH on Sushi, sell it on the expensive Uniswap. The searcher lands this trade RIGHT AFTER the whale — back-running it. No victim: the price already moved.

4/ On a mainnet fork: before the whale, arbing the two aligned pools LOSES ~$42K (just fees). After the whale de-pegs Uni, the same backrun makes +$10,099. Risk-free, created entirely by the whale's own trade.

5/ This is what keeps a token's price consistent across every exchange. Most "MEV" isn't predatory — it's bots racing to correct these gaps. And increasingly the profit is rebated to the user who caused it (MEV-Share).

6/ Proven on Sepolia: whale → backrun buy → backrun sell, three consecutive blocks, +5,294 USDC, all on Etherscan. Full code + breakdown 👇
https://github.com/nikshev/unstuck/tree/main/episodes/mev-06-backrun
