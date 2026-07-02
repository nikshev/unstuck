# 16 — Bubble Sort (Rust)

> The classic teaching sort: swap wrong-order neighbors pass by pass. Honest verdict included.

📺 Video: _(soon)_

## Watch it work ([`src/bin/passes.rs`](src/bin/passes.rs))
Prints the array after every pass — you can see the biggest value "bubble" to the end,
and the early-exit flag stop the sort as soon as a pass makes no swaps.

## Honest benchmark ([`src/bin/bench.rs`](src/bin/bench.rs))
30,000 items:
- reverse-sorted (worst): **~392 ms** — O(n²)
- already sorted (best, early exit): **~25 µs** — O(n)
- `std sort_unstable` on the worst case: **~19 µs** — the built-in beats bubble's best case

## Run
```bash
cargo run --release --bin passes
cargo run --release --bin bench
```
Use it to learn passes/swaps/invariants; use the built-in sort in real code.
