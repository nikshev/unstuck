# 05 — FizzBuzz (Rust)

> The classic interview filter — and why the version most people write is subtly wrong.

📺 Video: _(soon)_

## The bug  ([`src/bin/wrong.rs`](src/bin/wrong.rs))
Checking `% 3` before `% 15` means 15 prints **"Fizz"**, never "FizzBuzz" — the `% 15`
branch is dead code, because an `if / else if` chain stops at the first true branch.

## The fix  ([`src/bin/correct.rs`](src/bin/correct.rs))
Check the **most specific** case first.

```rust
if n % 15 == 0 { /* FizzBuzz */ }
else if n % 3 == 0 { /* Fizz */ }
else if n % 5 == 0 { /* Buzz */ }
```

## Order-proof  ([`src/bin/clean.rs`](src/bin/clean.rs))
Build the word with independent `if`s — no ordering to get wrong, and it scales.

## Run
```bash
cargo run --release --bin wrong     # 15 -> "Fizz"  (the bug)
cargo run --release --bin correct   # 15 -> "FizzBuzz"
cargo run --release --bin clean     # 15 -> "FizzBuzz"
```
