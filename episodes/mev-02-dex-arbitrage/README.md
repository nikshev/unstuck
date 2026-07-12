# MEV Explained — Ep 2: DEX Arbitrage (Uniswap v2 vs SushiSwap)

## 🎬 Watch

🔜 **Video coming soon.** [Subscribe on YouTube](https://www.youtube.com/channel/UC32d5uV5MEC1oMqVaVbQPNA) to catch it.

The oldest and purest MEV: the same token trades at **two different prices** on two exchanges, and
you pocket the gap — buy it cheap on one, sell it dear on the other, in **one atomic transaction**.
We reproduce it as a real Foundry test against a **mainnet fork**, and the profit prints for real.

## The idea in one test
`test/DexArb.t.sol` forks mainnet, has a **whale** dump WETH onto Uniswap (making WETH cheap there),
then the **attacker** buys that cheap WETH on Uniswap and sells it on SushiSwap where it's still
priced higher — ending with more USDC than it started. `assertGt` proves the profit.

## Run it yourself
Requires [Foundry](https://getfoundry.sh) and a mainnet RPC.

```bash
forge install foundry-rs/forge-std   # first time only
export ETH_RPC_URL=<your mainnet RPC>
forge test -vvv
```

You'll see `[PASS] test_arbProfit` with a log like `arb profit (USDC): 1331` — a real ~$1.3k arb
against live mainnet pools, on your own machine.

## Key idea
- **Atomic:** both swaps are in one transaction — either the whole arb profits, or it reverts and
  you only lose gas. You can never get stuck holding the token.
- **Whoever lands the tx first wins** — which is why searchers fight over gas (see Ep 1's PGA).
- **Next (Ep 3):** the same arbitrage with **zero capital**, using a flash loan.

## Sources
- Uniswap v2 / SushiSwap routers (mainnet) · Foundry: https://getfoundry.sh
- Flash Boys 2.0 (Daian et al., 2019): https://arxiv.org/abs/1904.05234
