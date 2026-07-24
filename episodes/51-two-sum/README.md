# ep43 — Two Sum (LeetCode 1), in Rust

Return the indices of the two numbers that add up to `target`. One pass with a **HashMap of value ->
index**: for each x, check if its **complement** (target - x) was already seen. O(n) time, O(n) space.

```bash
cargo run        # -> [0, 1], [1, 2], [0, 1]
```

The partner of x is fixed (target - x), so a HashMap turns "have I seen the complement?" into an instant
lookup instead of the brute-force O(n^2) double loop.
