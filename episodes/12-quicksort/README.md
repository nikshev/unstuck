# 12 — Quicksort + the O(n²) trap (Rust)

> Quicksort is O(n log n) on average, but a bad pivot makes it O(n²). Demonstrated by comparison count.

📺 Video: _(soon)_

## The trap ([`src/bin/bad.rs`](src/bin/bad.rs))
First-element pivot on already-sorted data → unbalanced splits → O(n²).
On 2000 sorted items: **~1,999,000 comparisons**.

## The fix ([`src/bin/good.rs`](src/bin/good.rs))
```rust
let pivot = v[v.len() / 2];   // middle pivot → balanced partitions → O(n log n)
```
Same 2000 items: **~18,000 comparisons**. Use middle, random, or median-of-three.

## Run
```bash
cargo run --release --bin bad    # first-element pivot on sorted data
cargo run --release --bin good   # middle pivot
```
Average O(n log n), worst O(n²) — decided entirely by pivot choice.
