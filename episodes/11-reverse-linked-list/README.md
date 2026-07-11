# 11 — Reverse a Linked List (Rust)

## 🎬 Watch

[![Watch on YouTube](https://img.youtube.com/vi/UOf6XrXZoZM/maxresdefault.jpg)](https://youtu.be/UOf6XrXZoZM)

▶️ **Watch: https://youtu.be/UOf6XrXZoZM**


> Reverse a singly linked list. Naive rebuild uses O(n) extra space; in-place pointer reversal uses O(1).

📺 Video: _(soon)_

## In-place ([`src/bin/inplace.rs`](src/bin/inplace.rs))
```rust
while let Some(mut node) = head {
    head = node.next.take(); // detach the rest
    node.next = prev;        // point this node backward
    prev = Some(node);       // advance
}
prev  // the new head
```
`.take()` moves the rest of the list out (leaving `None`) so Rust's one-owner rule is satisfied and you can rewire safely — no dangling pointers, ever.

## Naive ([`src/bin/naive.rs`](src/bin/naive.rs))
Collect values into a `Vec`, reverse it, rebuild a new list — O(n) extra space.

## Run
```bash
cargo run --release --bin naive
cargo run --release --bin inplace
```
Both O(n) time; in-place is O(1) extra space. `type Link = Option<Box<Node>>` — Rust's safe nullable pointer.
