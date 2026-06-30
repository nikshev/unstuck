# 08 — Binary Search (Rust)

> Find a value in a sorted list in ~log n steps. 10,000,000 comparisons (linear) → 23 (binary).

📺 Video: _(soon)_

## The bug-free template ([`src/bin/binary.rs`](src/bin/binary.rs))
```rust
let mid = lo + (hi - lo) / 2;   // NOT (lo + hi) / 2 — that overflows
if v[mid] == target { /* found */ }
else if v[mid] < target { lo = mid + 1; }
else { hi = mid; }              // hi is EXCLUSIVE; loop while lo < hi
```
Avoids the three classic bugs: midpoint overflow, off-by-one, and infinite loops.

## Run
```bash
cargo run --release --bin linear   # O(n):     10,000,000 comparisons
cargo run --release --bin binary   # O(log n): 23 comparisons
```
Only works on **sorted** data. O(log n) time, O(1) space.
