# Rust Coding Challenges — Ep 35: Best Time to Buy and Sell Stock (LeetCode 121)

## 🎬 Watch

🔴 **New episode** — [Subscribe](https://www.youtube.com/channel/UC32d5uV5MEC1oMqVaVbQPNA?sub_confirmation=1) to catch it when it drops.

One transaction — buy on one day, sell on a later day — for the maximum profit. The brute-force check of
every pair is **O(n²)**; the one-pass greedy is **O(n)**. Sweep the prices left to right and carry two
numbers: the **cheapest price seen so far** and the **best profit so far**. Each day you either found a new
low or beat your best by selling today — you never look back, because the cheapest buy is always already
behind you.

## The code

`src/main.rs` — a one-pass `max_profit(prices: &[i32]) -> i32` tracking `min_price` and `best`, plus a
`main` that runs `[7, 1, 5, 3, 6, 4]` and two edge cases (all-descending, empty).

## Run it yourself

Requires [Rust](https://rustup.rs).

```bash
cargo run
```

Output:

```
prices:      [7, 1, 5, 3, 6, 4]
max profit:  5
descending:  0
empty:       0
```

- **Time:** `O(n)` — a single pass over the prices.
- **Space:** `O(1)` — just two running values, no DP table.

> The whole trick: the cheapest buy is always behind you, so one sweep is enough. Buy at **1**, sell at
> **6** → **5**. If prices only ever fall, no trade beats doing nothing → **0**.
