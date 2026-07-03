# 20 — Insertion Sort (Rust)

> Grow a sorted region on the left, inserting one element at a time. O(n²) worst, O(n) nearly-sorted.

📺 Video: _(soon)_

## The algorithm ([`src/bin/bench.rs`](src/bin/bench.rs))
```rust
for i in 1..a.len() {
    let key = a[i];
    let mut j = i;
    while j > 0 && a[j-1] > key { a[j] = a[j-1]; j -= 1; } // shift bigger right
    a[j] = key;                                            // drop the key in
}
```

## Run
```bash
cargo run --release --bin passes   # watch it sort, pass by pass
cargo run --release --bin bench    # 20k: reverse 109ms · sorted 12µs · nearly-sorted 18µs
```
Stable, in-place. Its O(n) best case is why Timsort/introsort fall back to it for small/nearly-sorted slices.
