# 13 — Valid Anagram (Rust)

> Are two strings anagrams? Sorting is O(n log n); counting letters is O(n) (~15× faster on 1M chars).

📺 Video: _(soon)_

## Count approach ([`src/bin/count.rs`](src/bin/count.rs))
```rust
let mut counts = [0i32; 26];
for c in a.bytes() { counts[(c - b'a') as usize] += 1; }
for c in b.bytes() { counts[(c - b'a') as usize] -= 1; }
counts.iter().all(|&v| v == 0)   // all zero => anagram
```
`[i32; 26]` for lowercase a–z (O(1) space); use a `HashMap<char, i32>` for arbitrary Unicode.

## Sort approach ([`src/bin/sort.rs`](src/bin/sort.rs))
Sort both strings' chars and compare — O(n log n).

## Run
```bash
cargo run --release --bin sort    # ~16 ms on 1M chars
cargo run --release --bin count   # ~1 ms  (O(n))
```
Add a length check first — different lengths can't be anagrams.
