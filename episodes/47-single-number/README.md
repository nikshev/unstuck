# Rust Coding Challenges — Ep 39: Single Number (LeetCode 136)

## 🎬 Watch

🔴 **New episode** — [Subscribe](https://www.youtube.com/channel/UC32d5uV5MEC1oMqVaVbQPNA?sub_confirmation=1) to catch it when it drops.

Every value in the array appears **exactly twice** — except one, which appears **once**. Find the loner.
The obvious way keeps a `HashSet` (memory that grows with the array). The beautiful way is a single
bitwise trick, **XOR**: `a ^ a == 0` (a matched pair cancels itself out) and `a ^ 0 == a` (the survivor
passes through untouched). XOR is also commutative, so it doesn't matter where the duplicates sit.

## The code

`src/main.rs` — `single_number(nums: Vec<i32>) -> i32`:

- Start an accumulator at `0` (the XOR identity).
- Sweep the array once, `acc ^= x` for every value.
- Every pair wipes to `0`; only the unpaired number is left standing — return it.

`main` runs `[2, 2, 1]`, `[4, 1, 2, 1, 2]`, and the single-element `[7]`.

## Run it yourself

Requires [Rust](https://rustup.rs).

```bash
cargo run
```

Output:

```
[2, 2, 1]  ->  1
[4, 1, 2, 1, 2]  ->  4
[7]  ->  7
```

- **Time:** `O(n)` — one pass over the array.
- **Space:** `O(1)` extra — a single accumulator, no `HashSet`, no sorting, no matter how long the array is.

> Why XOR beats a hash set: counting occurrences costs memory that grows with `n`. XOR folds the whole
> array into one integer — pairs annihilate, the loner survives — so it's one pass and one integer of
> memory. Whenever you see "everything appears twice except one," reach for XOR.
