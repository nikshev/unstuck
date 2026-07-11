# 07 — Valid Parentheses (Rust)

## 🎬 Watch

[![Watch on YouTube](https://img.youtube.com/vi/o-szOloQtZI/maxresdefault.jpg)](https://youtu.be/o-szOloQtZI)

▶️ **Watch: https://youtu.be/o-szOloQtZI**


> Are the brackets correctly matched and nested? The naive "just count" check is wrong; a stack fixes it.

📺 Video: _(soon)_

## Why counting fails ([`src/bin/naive.rs`](src/bin/naive.rs))
Counting opens vs closes passes `([)]` — equal counts, but the brackets are interleaved wrong. Counting ignores order.

## The stack ([`src/bin/stack.rs`](src/bin/stack.rs))
Push opens; on a close, pop and check it's the matching open; the stack must be empty at the end.
```rust
')' => if stack.pop() != Some('(') { return false; },
```

## Run
```bash
cargo run --release --bin naive    # ([)] -> true  (the bug)
cargo run --release --bin stack    # ([)] -> false (correct)
```
O(n) time, O(n) space. The last-opened bracket must close first → LIFO → a stack.
