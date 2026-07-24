# mev11 — Quantifying MEV (Inspect a Block, MEV-Inspect style)

Not an attack build — a **measurement**. We reproduce a **sandwich** (front-run + victim + back-run on a
constant-product pool) and then put an exact number on the searcher's profit by reading the **call
trace**, exactly how [mev-inspect](https://github.com/flashbots/mev-inspect-py) quantifies MEV.

The method is one idea: **follow the searcher's WETH, in vs out.** On the front-run it sends WETH into the
pool; on the back-run the pool sends more WETH back. The difference is the profit — and it comes straight
out of the victim's slippage.

## Reproduce it yourself

```bash
forge test -vv   --match-test test_sandwich    # the profit ledger
forge test -vvvv --match-test test_sandwich    # the full call TRACE (read the transfers)
```

## What the trace shows

```
Searcher::frontrun(10e18)               # searcher buys, just before the victim
  Pool::buyToken(10e18)
    Transfer  Searcher -> Pool   10 WETH        [1e19]   <-- WETH IN
    Transfer  Pool -> Searcher   9,066 TKN
Pool::buyToken(20e18)                    # the VICTIM's big buy, at the worse price
Searcher::backrun()                     # searcher sells, just after
  Pool::sellToken(9,066 TKN)
    Transfer  Pool -> Searcher   13.66 WETH     [1.366e19]  <-- WETH OUT
```

**profit = WETH out − WETH in = 13.66 − 10 = 3.66 WETH** (the victim's slippage). That's the number
MEV-Inspect reports; at scale it matches this buy-then-sell-around-a-victim shape over every block's trace.

## Files
- `src/Pool.sol` — a minimal constant-product AMM (the thing a sandwich preys on)
- `src/Searcher.sol` — `frontrun()` / `backrun()` — the sandwich
- `test/Sandwich.t.sol` — reproduces the sandwich and prints the profit; `-vvvv` shows the trace
- `script/SandwichSepolia.s.sol` — the same lab as a deploy (also runnable on a local `anvil`)
