# 04 — Merge Sort (Rust)

> Sorting in O(n log n) with divide & conquer — and why it destroys the naive O(n²) sort.

📺 Video: _(soon)_

## Naive — O(n²)  ([`src/bin/naive.rs`](src/bin/naive.rs))
Bubble sort: swap adjacent pairs pass after pass (with an early-exit flag).

## Merge sort — O(n log n)  ([`src/bin/merge.rs`](src/bin/merge.rs))
Split the slice in half, sort each half recursively, then merge two sorted halves
with a two-pointer merge.

```rust
let left = merge_sort(&a[..mid]);
let right = merge_sort(&a[mid..]);
merge(&left, &right)
```

## Run
```bash
cargo run --release --bin naive   # bubble sort, ~300 ms on 30k reverse-sorted
cargo run --release --bin merge   # merge sort, ~1.4 ms
```
Needs the Rust toolchain (`rustup`).
