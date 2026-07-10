# Longest Substring Without Repeating Characters (Rust · LeetCode 3)

📺 Video: **Longest Substring Without Repeating — Sliding Window (Rust)**

Find the length of the longest run of characters with no repeats.

- **Brute force** `longest_brute` — for every start, extend until a repeat. **O(n²)**.
- **Sliding window** `longest` — one pass: grow the right edge; when a char repeats, jump the
  **left** edge just past its last position (tracked in a `HashMap`). **O(n)**.

```bash
cargo run --release --bin longest
```
`"abcabcbb" -> 3`, `"bbbbb" -> 1`, `"pwwkew" -> 3`. Both versions agree; the window does it in one pass.
