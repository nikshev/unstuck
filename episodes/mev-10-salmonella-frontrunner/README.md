# mev10 — Generalized Frontrunners & the Salmonella Honeypot

A **generalized front-runner** copies any profitable-looking pending transaction's calldata and runs it
first with higher gas — trusting the transaction without understanding it. The **Salmonella** honeypot
is built for exactly that bot: it emits the standard `Transfer` **event for the full amount**, but for
anyone who isn't the token's owner, **only 1% actually moves**. So a copy bot (or a naive simulation)
reads the event, sees a big transfer, and pounces — and walks off with almost nothing. The event lies;
only the real balance tells the truth.

The defense: **verify the real balance delta** (pull, then require `balanceAfter - balanceBefore ==
amount`), and — the strongest real-world defense — **private orderflow**, so the bot never sees the
transaction in the mempool at all.

## Reproduce it yourself

```bash
export RPC="https://your-sepolia-rpc-endpoint"
export PK="0xYOUR_FUNDED_SEPOLIA_PRIVATE_KEY"   # the deployer is the honeypot owner
./reproduce.sh          # forge tests + all 3 acts, live on Sepolia
```

## The event lies — see it on Etherscan

The trap tx —
[`0x9d447a…5f8517`](https://sepolia.etherscan.io/tx/0x9d447a321d625aaa1cfafd3170b6b4b1dbe3ba69841b1d013a596072e85f8517)
— shows **`For 1,000 SALM`** transferred from the front-runner to the sink. But read the real balance:
`cast call $SALM "balanceOf(address)(uint256)" $SINK` returns **`10`**. Only 1% ever moved.

## The exact transactions (Sepolia)

· token (SALM) `0xa0cbbA7a1a45b6F494aEc4aB5Bef7C2F37e9CF91` · bot `0x5436a84B2c8A71EdF5638819895aFd9419b68946` · safe `0xd5D9201cd18f8305ab5196E1D7c6084cc60d8f19`

- **Act 1 — honest** (owner moves it, full amount arrives): [0xb7ebe2…82d6fd](https://sepolia.etherscan.io/tx/0xb7ebe2b37b8ce0afb8d7ad6be4311c5ca9850743d4c903fa065d03071782d6fd) — owner → Bob 1,000 SALM, Bob really receives 1,000
- **Act 2 — trap** (front-runner copies it): [0x9d447a…5f8517](https://sepolia.etherscan.io/tx/0x9d447a321d625aaa1cfafd3170b6b4b1dbe3ba69841b1d013a596072e85f8517) — event says 1,000, sink really receives **10**
- **Act 3 — fixed** (SafeReceiver verifies the delta): `SafeReceiver.pull(...)` reverts `short transfer` — it expected 1,000, saw 10 arrive, so it refuses

## Files
- `src/Salmonella.sol` — the honeypot token (owner moves full; others 1%; event always reports full)
- `src/SafeReceiver.sol` — the defense: verify the real balance delta, revert on a short transfer
- `src/Bot.sol` — a stand-in generalized front-runner (copies the move)
- `test/Salmonella.t.sol` — the three acts as Foundry tests
- `script/SalmonellaSepolia.s.sol` — the on-chain deploy used above
