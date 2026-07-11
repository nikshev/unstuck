# Coin Change — Min Coins (Rust · LeetCode 322)

📺 Video: **Coin Change — Dynamic Programming from Scratch (Rust)**

Fewest coins that add up to `amount`.

- **Naive recursion** `min_coins_naive` — try every coin as the last one, recurse on the rest.
  The same amounts get recomputed in different branches → **exponential**.
- **Bottom-up DP** `min_coins` — `dp[a]` = fewest coins to make `a`; fill `1..=amount`, smallest
  first: `dp[a] = min over coins of dp[a - coin] + 1`. Each amount solved **once**. **O(amount × coins)**.

```bash
cargo run --release --bin coin
```
`amount 6 -> 2` (3+3), `11 -> 3` (4+4+3). Both versions agree; DP just never recomputes a subproblem.
