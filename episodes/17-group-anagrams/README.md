# 17 — Group Anagrams (Rust)

## 🎬 Watch

[![Watch on YouTube](https://img.youtube.com/vi/Kqfi3_vYpFA/maxresdefault.jpg)](https://youtu.be/Kqfi3_vYpFA)

▶️ **Watch: https://youtu.be/Kqfi3_vYpFA**


> Bucket words made of the same letters. The trick: every anagram shares one canonical
> sorted form — use it as a HashMap key.

📺 Video: _(soon)_

## The key trick ([`src/bin/key.rs`](src/bin/key.rs))
```rust
let mut key = w.as_bytes().to_vec();
key.sort();                              // "eat","tea","ate" -> all "aet"
map.entry(key).or_default().push(w.clone());
```
One pass, one hash op per word. 6000 words: **~1 ms** (vs **~153 ms** pairwise — see
[`src/bin/pairs.rs`](src/bin/pairs.rs)).

## Run
```bash
cargo run --release --bin pairs   # O(n²) pairwise comparison
cargo run --release --bin key     # sorted-key HashMap
```
Even faster key: a `[u8; 26]` letter-count (no sorting). The reusable lesson: to group
similar things, find a canonical form and hash by it.
