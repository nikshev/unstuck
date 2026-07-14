# 23 — Top K Frequent Elements / Bucket Sort O(n) (Rust)

## 🎬 Watch

[![Watch on YouTube](https://img.youtube.com/vi/8deHjXutjlg/maxresdefault.jpg)](https://youtu.be/8deHjXutjlg)

▶️ **Watch: https://youtu.be/8deHjXutjlg**

> Find the k most frequent numbers. The obvious way — count, then sort by frequency — is O(n log n).
> Bucket sort does it in **O(n)**: index the buckets BY frequency, then read from the top.

## The core ([`src/main.rs`](src/main.rs))
```rust
fn top_k_frequent(nums: Vec<i32>, k: usize) -> Vec<i32> {
    // 1) count how often each number appears
    let mut freq: HashMap<i32, usize> = HashMap::new();
    for &n in &nums { *freq.entry(n).or_insert(0) += 1; }
    // 2) bucket the numbers by their frequency (index = count)
    let mut buckets: Vec<Vec<i32>> = vec![Vec::new(); nums.len() + 1];
    for (&num, &count) in &freq { buckets[count].push(num); }
    // 3) read buckets from the highest frequency down, take k
    let mut out = Vec::with_capacity(k);
    for count in (1..buckets.len()).rev() {
        for &num in &buckets[count] {
            out.push(num);
            if out.len() == k { return out; }
        }
    }
    out
}
```

## Run it yourself
Requires [Rust](https://rustup.rs).

```bash
cargo run     # -> [1, 2] / [6, 4] / [7]
cargo test    # 3 passing tests
```

## Why it's O(n)
- Count frequencies: one pass over the array → O(n)
- Fill buckets (index = frequency): one pass over the counts → O(n)
- Read buckets top-down, take k: O(n) total cells
- No sort → beats the obvious O(n log n). (A min-heap of size k is the classic alternative at O(n log k).)

## Sources
- LeetCode 347 — Top K Frequent Elements
- Rust std `HashMap`: https://doc.rust-lang.org/std/collections/struct.HashMap.html

---
*Part of the [0xUnstuck](https://github.com/nikshev/unstuck) Rust Coding Challenges series.*
