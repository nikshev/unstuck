# Rust Coding Challenges — Ep 27: Detect a Linked List Cycle (Floyd's Tortoise & Hare)

📅 **Premieres Jul 19, 2026.** [Subscribe on YouTube](https://www.youtube.com/channel/UC32d5uV5MEC1oMqVaVbQPNA) to catch it.

How do you find a loop in a linked list without marking a single node? **Two runners, one twice as
fast.** Floyd's tortoise & hare walks a slow pointer one step and a fast pointer two — on a straight
list the fast one falls off the end (no cycle); on a looping list the fast one laps the slow one and
they land on the same node. **O(n) time, O(1) space.**

**The Rust twist:** an owned `Box`-based list literally can't form a cycle — single ownership forbids
it — so we model the list as nodes in a `Vec` with index "pointers" that can point backward.

`src/main.rs` builds the naive `HashSet` version (O(n) space) and Floyd's (O(1) space), and runs both
on a cyclic and an acyclic list.

## Run it
```bash
cargo run
```
```
list: 1 -> 2 -> 3 -> None

cyclic list  ->  HashSet: true   Floyd: true
acyclic list ->  HashSet: false  Floyd: false
```

LeetCode #141 · https://leetcode.com/problems/linked-list-cycle/
