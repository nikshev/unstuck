# 19 — Maximum Subarray / Kadane's Algorithm (Rust)

## 🎬 Watch

[![Watch on YouTube](https://img.youtube.com/vi/2CmFgGeBC1k/maxresdefault.jpg)](https://youtu.be/2CmFgGeBC1k)

▶️ **Watch: https://youtu.be/2CmFgGeBC1k**


> Find the contiguous subarray with the largest sum. Brute force is O(n²); Kadane's is O(n).

📺 Video: _(soon)_

## Kadane ([`src/bin/kadane.rs`](src/bin/kadane.rs))
```rust
let (mut current, mut best) = (0i64, i64::MIN);
for &x in nums {
    current += x;                 // extend the run
    best = best.max(current);     // record the best so far
    if current < 0 { current = 0; } // drop a negative run, start fresh
}
```
`best` starts at `i64::MIN` (not 0) — that's what makes all-negative arrays correct.

## Run
```bash
cargo run --release --bin brute    # O(n²), ~220 ms on 30k
cargo run --release --bin kadane   # O(n),  ~18 µs on 30k
```
LeetCode #53. One pass, O(1) space.
