# MEV Explained — Ep 3: Flash-Loan Arbitrage (the same arb, ZERO capital)

## 🎬 Watch

🔜 **Video coming soon.** [Subscribe on YouTube](https://www.youtube.com/channel/UC32d5uV5MEC1oMqVaVbQPNA) to catch it.

In Ep 2 we arbitraged Uniswap vs SushiSwap — but needed $50k of our own. Now we do the **exact same
trade with zero capital**, by borrowing the money with an **Aave v3 flash loan** and repaying it in
the same transaction. This is the tool every real searcher uses.

## The idea in one test
`test/FlashArb.t.sol` forks mainnet, a whale makes WETH cheap on Uniswap, then `FlashArb.startArb`:
- flash-borrows USDC from Aave (no collateral),
- buys cheap WETH on Uniswap, sells it dear on Sushi,
- repays Aave the loan + fee, keeps the rest.

`assertGt` proves profit, and the contract **starts with exactly 0 USDC**.

## Run it yourself
Requires [Foundry](https://getfoundry.sh) and a mainnet RPC.
```bash
forge install foundry-rs/forge-std   # first time only
export ETH_RPC_URL=<your mainnet RPC>
forge test -vvv
```
You'll see `[PASS] test_flashArb` and `profit (USDC) with 0 capital: 1306` — a real ~$1.3k arbitrage
funded entirely by a flash loan, against live mainnet pools.

## Key idea
- **Zero capital:** you borrow millions you don't have, for one transaction.
- **Atomic:** if the trade doesn't profit, the whole transaction reverts — you lose only gas.
- This is why the public mempool is a war zone of bots racing to land these txs.
- **Next (Ep 4):** MEV that targets *you* — the sandwich attack.

## Sources
- Aave v3 flash loans: https://docs.aave.com/developers/guides/flash-loans
- Flash Boys 2.0 (Daian et al., 2019): https://arxiv.org/abs/1904.05234
- Foundry: https://getfoundry.sh

---
*Educational. Runs on a private local fork — no real users or funds. Part of the [0xUnstuck](https://github.com/nikshev/unstuck) MEV Explained series.*
