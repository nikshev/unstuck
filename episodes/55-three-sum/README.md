# 3Sum (LeetCode 15) — in Rust
Find all unique triplets that sum to 0. **Sort**, then fix one anchor and **two-pointer** the rest:
sum too small → raise lo, too big → lower hi, exactly 0 → record and skip duplicates. O(n²) time.
## Run
```
cargo run
```
Prints `[[-1,-1,2],[-1,0,1]]`, `[]`, `[[0,0,0]]`.
