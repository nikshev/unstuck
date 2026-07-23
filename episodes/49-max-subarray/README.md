# ep41 — Maximum Subarray (LeetCode 53), in Rust

Find the contiguous subarray with the largest sum. **Kadane's algorithm**: the best run *ending here*
is either the element alone, or the element added onto the best run ending just before it —
`cur = max(x, cur + x)`. Track that and the best ever seen. One pass, **O(n) time, O(1) space**.

```bash
cargo run        # -> 6, then 1, then -1
```

Seed both trackers with `nums[0]` (not 0) so an all-negative array returns its largest single element.
