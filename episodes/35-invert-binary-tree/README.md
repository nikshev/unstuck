# 35 — Invert a Binary Tree (LeetCode 226) · Rust

## 🎬 Watch

📅 **Premieres Jul 17, 2026.** [Subscribe on YouTube](https://www.youtube.com/channel/UC32d5uV5MEC1oMqVaVbQPNA) to catch it.

> The famous whiteboard question. Inverting a tree just means **mirroring** it — at every node, swap the
> left and right children. Recursion carries that one swap everywhere, and an empty branch stops it. **O(n)**.

## The core ([`src/main.rs`](src/main.rs))
```rust
fn invert(root: &mut Tree) {
    if let Some(node) = root {                            // empty spot? nothing to do
        std::mem::swap(&mut node.left, &mut node.right);  // swap THIS node's two children
        invert(&mut node.left);                           // recurse into the (new) left
        invert(&mut node.right);                          // recurse into the (new) right
    }
}
```

## Run it
```bash
cargo run
# before: [4, 2, 7, 1, 3, 6, 9]
# after:  [4, 7, 2, 9, 6, 3, 1]
```
`level_order` reads the tree breadth-first, so the reversed bottom row makes the mirror obvious.

## Key idea
- Invert = swap every node's two children.
- One `std::mem::swap` per node — no clones, no copies; then recurse into both children.
- Base case: an empty branch (`None`) ends the recursion.
- **O(n)** time — you visit each node exactly once.
