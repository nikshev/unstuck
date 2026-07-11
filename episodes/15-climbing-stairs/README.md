# 15 — Climbing Stairs (Rust, DP)

## 🎬 Watch

[![Watch on YouTube](https://img.youtube.com/vi/0AZo5iaRpFs/maxresdefault.jpg)](https://youtu.be/0AZo5iaRpFs)

▶️ **Watch: https://youtu.be/0AZo5iaRpFs**


> How many ways to climb n stairs taking 1 or 2 steps? ways(n) = ways(n−1) + ways(n−2) —
> naive recursion explodes to O(2ⁿ); bottom-up DP does it in O(n)/O(1).

📺 Video: _(soon)_

## The explosion ([`src/bin/naive.rs`](src/bin/naive.rs))
Direct recursion recomputes overlapping subproblems: at n=40 that's **331,160,281 function calls (~440 ms)**.

## The DP fix ([`src/bin/dp.rs`](src/bin/dp.rs))
```rust
let (mut prev, mut curr) = (1u64, 1u64);
for _ in 2..=n { let next = prev + curr; prev = curr; curr = next; }
```
Same answer in **39 loop steps (~4 µs)**. Compute each subproblem once, keep only the last two.

## Run
```bash
cargo run --release --bin naive
cargo run --release --bin dp
```
Base cases: ways(0)=ways(1)=1. Use u64 — the counts grow fast (it's Fibonacci in disguise).
