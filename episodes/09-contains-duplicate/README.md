# 09 — Contains Duplicate (Rust)

> Does any value appear twice? Brute force is O(n²); a HashSet is O(n).

📺 Video: _(soon)_

## The HashSet trick ([`src/bin/set.rs`](src/bin/set.rs))
`HashSet::insert` returns `false` if the value was already present — so the check is one line:
```rust
if !seen.insert(x) { return true; }   // duplicate!
```

## Run
```bash
cargo run --release --bin brute   # O(n²)  ~240 ms on 30k
cargo run --release --bin set     # O(n)   ~1.5 ms
```
HashSet: O(n) time / O(n) space. Alternative: sort then check neighbours — O(n log n) time, O(1) space.
