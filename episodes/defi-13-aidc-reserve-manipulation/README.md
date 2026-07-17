# DeFi Exploits, Explained — Ep 13: AIDC Reserve Manipulation

## 🎬 Watch

📅 **Premieres Jul 17, 2026.** [Subscribe on YouTube](https://www.youtube.com/channel/UC32d5uV5MEC1oMqVaVbQPNA) to catch it.

A token that got drained by its own **burn** function. AIDC looked like a normal fee-on-transfer coin
on BNB Chain — until its burn logic destroyed tokens **out of the liquidity pool** instead of the
seller, then called `sync()` on the pair. Each burn silently shrank the AIDC reserve while the WBNB
side was untouched, so by constant-product math the price of AIDC spiked with **no real trade**. The
attacker just poked it until AIDC was ~100× overpriced, then swapped their cheap AIDC into the pool
and walked out with **half its WBNB — about $121K (220 WBNB)** on 2026-06-29.

## The idea in one test
`test/ReserveManip.t.sol` builds a minimal version:
- `AidcTokenBuggy` (VULNERABLE) — an ordinary ERC-20 whose `executeAccumulatedBurn(pair, amount)` burns AIDC from **`balanceOf[pair]`** (the pool!) and then calls `pair.sync()`.
- `Pair` — a minimal constant-product AMM whose `sync()` caches its **live** balances (the primitive the exploit abuses), and `swapAidcForWbnb()` prices by `x*y=k`.
- `AidcTokenFixed` — the two-line fix: `require(balanceOf[msg.sender] >= amount)` + burn from **`msg.sender`**, and **no `sync()`**.

`test_drain` seeds a fair 100 WBNB / 1,000,000 AIDC pool, burns 990k AIDC **from the pool** (reserve → 10k, AIDC ×100), then swaps 10k AIDC for **50 WBNB** — half the pool. `test_fixed` runs the same burn against the fixed token: it **reverts**, and the reserves are unchanged.

> A burn must debit the account that **owes** it (the seller). The moment a token can mutate the
> pair's balance and call `sync()`, it hands anyone a free reserve-manipulation lever.

## Run it yourself
Requires [Foundry](https://getfoundry.sh).

```bash
forge install foundry-rs/forge-std   # first time only
forge test -vv
```

You'll see `[PASS] test_drain` with a step-by-step reserve ledger (100 WBNB / 1,000,000 AIDC →
100 / 10,000 → 50 WBNB drained) and `[PASS] test_fixed` (the malicious burn reverts, reserves intact).

## Proven on Sepolia
The token + pair were deployed to the Sepolia testnet and hit with the same burn-and-swap:

| Contract | Action | Tx | Result |
|---|---|---|---|
| Vulnerable pair `0x2428…98d7` | `swapAidcForWbnb` (after the pool burn) | [`0x4192…0640`](https://sepolia.etherscan.io/tx/0x4192630216d13168375942e75f7f898da4eb600c5ec9010785992cd322880640) | ✅ Success — WBNB reserve 100 → 50 |
| Fixed token `0xbcd3…b515` | `executeAccumulatedBurn(pair, 990000)` | [`0x3ef9…fc5e`](https://sepolia.etherscan.io/tx/0x3ef9f033481976acd7e2052b2d425b9fb6e0d94e4b5b88f5a76c57a429fafc5e) | ❌ Fail — `execution reverted` (`'bal'`) |

## Key idea
- A burn must debit the **seller** — never the pool. Mutating pair balances + `sync()` inside a token is a free reserve-manipulation primitive.
- Constant-product price is only as honest as the reserves you feed it; deflate one side and the price prints.
- Fee-on-transfer tokens should touch **only** the sender and recipient, and never call `sync()` on the AMM.

## Sources
- AIDC exploit (BNB Chain, 2026-06-29, ~$121K / 220 WBNB): https://www.cryptotimes.io/2026/06/29/aidc-token-burn-bug-exploit-drains-121k-from-pancakeswap/
- SlowMist incident thread: https://twitter.com/SlowMist_Team/status/2071437371590238249
- Attack tx (BscScan): https://bscscan.com/tx/0x66960f7febf399fa8bd94904398f535c500f4f575dbf025de7b9ab450342645e
- Vulnerable AIDCToken source (BscScan): https://bscscan.com/address/0x5021d71859f81b4c905b573591db8f9cc4a0c6fe#code
- Uniswap/PancakeSwap V2 pair `sync()` & reserves: https://docs.uniswap.org/contracts/v2/concepts/protocol-overview/how-uniswap-works
- Foundry: https://getfoundry.sh
