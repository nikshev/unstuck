# 03 — Two Sum (Rust)

## 🎬 Watch

[![Watch on YouTube](https://img.youtube.com/vi/2f_GHO8M8-E/maxresdefault.jpg)](https://youtu.be/2f_GHO8M8-E)

▶️ **Watch: https://youtu.be/2f_GHO8M8-E**


> Find the two indices whose values add up to a target. The obvious solution is O(n²);
> a one-pass hash map makes it O(n).

📺 Video: _(soon)_

## Naive — O(n²)  ([`src/bin/brute.rs`](src/bin/brute.rs))
Check every pair with nested loops. Correct, but quadratic — it crawls on big inputs.

## Optimal — O(n)  ([`src/bin/optimal.rs`](src/bin/optimal.rs))
Scan once. For each number, look up its complement (`target - n`) in a `HashMap`
**before** inserting the current number, so a value never matches itself.

```rust
if let Some(&j) = seen.get(&(target - n)) { return Some((j, i)); }
seen.insert(n, i);
```

## Run
```bash
cargo run --release --bin brute     # ~600 ms on 50k worst-case
cargo run --release --bin optimal   # ~3 ms  — same answer, O(n)
```
Needs the Rust toolchain (`rustup`). No wallet/network — pure algorithm.
