# 33 — Search in Rotated Sorted Array (LeetCode 33) · Rust

## 🎬 Watch

🔜 **Video coming soon.** [Subscribe on YouTube](https://www.youtube.com/channel/UC32d5uV5MEC1oMqVaVbQPNA) to catch it.

> A sorted array, rotated by some unknown amount. Plain binary search breaks — but at any midpoint
> **one half is always sorted**. Find which, check if the target is in it, and narrow. Still **O(log n)**.

## The core ([`src/main.rs`](src/main.rs))
```rust
fn search(nums: Vec<i32>, target: i32) -> i32 {
    let (mut lo, mut hi) = (0i32, nums.len() as i32 - 1);
    while lo <= hi {
        let mid = (lo + hi) / 2;
        if nums[mid as usize] == target { return mid; }
        if nums[lo as usize] <= nums[mid as usize] {          // left half sorted
            if nums[lo as usize] <= target && target < nums[mid as usize] { hi = mid - 1; }
            else { lo = mid + 1; }
        } else {                                              // right half sorted
            if nums[mid as usize] < target && target <= nums[hi as usize] { lo = mid + 1; }
            else { hi = mid - 1; }
        }
    }
    -1
}
```

## Run it yourself
```bash
cargo run     # -> 4 / -1 / -1
cargo test    # 4 passing tests
```

## Key idea
- One comparison — `nums[lo] <= nums[mid]` — tells you which half is sorted.
- A range check tells you whether the target is in that sorted half → go there, else the other.
- Every step still halves the window, so it stays **O(log n)**.

## Sources
- LeetCode 33 — Search in Rotated Sorted Array

---
*Part of the [0xUnstuck](https://github.com/nikshev/unstuck) Rust Coding Challenges series.*
