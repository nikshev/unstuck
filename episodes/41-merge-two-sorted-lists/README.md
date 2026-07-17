# Rust Coding Challenges — Ep 33: Merge Two Sorted Linked Lists (LeetCode 21)

## 🎬 Watch

🔔 [Subscribe on YouTube](https://www.youtube.com/channel/UC32d5uV5MEC1oMqVaVbQPNA?sub_confirmation=1) — a coding challenge solved in Rust, explained line by line, every episode.

Merge two already-sorted linked lists into one sorted list. The recursive solution is a **zipper**:
compare the two heads, take the smaller one, recurse on the rest. In Rust, `merge` takes **ownership** of
both `Option<Box<ListNode>>` and relinks them — so the dangling-pointer bugs this classic problem is
famous for simply can't compile.

## The code

`src/main.rs` — a recursive `merge`, plus `from_vec` / `print_list` helpers and a `main` that merges
`[1, 3, 5, 7]` and `[2, 4, 6]`.

## Run it yourself

Requires [Rust](https://rustup.rs).

```bash
cargo run
```

Output:

```
merged: 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> None
```

- **Time:** `O(n + m)` — each node is visited once.
- **Space:** `O(1)` extra — nodes are **moved**, never copied (the recursion stack aside).

> The whole trick: `merge` **consumes** both lists and hands back one. No `.clone()`, no raw pointers,
> no null-deref — the borrow checker does the bookkeeping for you.
