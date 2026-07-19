# Rust Coding Challenges — Ep 37: Product of Array Except Self (LeetCode 238)

## 🎬 Watch

🔴 **New episode** — [Subscribe](https://www.youtube.com/channel/UC32d5uV5MEC1oMqVaVbQPNA?sub_confirmation=1) to catch it when it drops.

Return an array where `output[i]` is the product of **every element except `nums[i]`** — with **no division**
and in **O(n)**. The trick is to split each answer into two halves: the product of everything to the **left**
of `i` times the product of everything to the **right** of `i`. Two sweeps, no division (so a single `0`
can't blow it up), and `nums[i]` is never multiplied into its own slot.

## The code

`src/main.rs` — `product_except_self(nums: Vec<i32>) -> Vec<i32>`:

- **Pass 1 (left → right):** fill `output[i]` with the running **prefix** product of everything before `i`.
- **Pass 2 (right → left):** multiply each `output[i]` by the running **suffix** product of everything after
  `i`. Left × right = the product of all the others.

`main` runs `[1, 2, 3, 4]` plus the one-zero and two-zero edge cases.

## Run it yourself

Requires [Rust](https://rustup.rs).

```bash
cargo run
```

Output:

```
[1, 2, 3, 4]  ->  [24, 12, 8, 6]
[-1, 1, 0, -3, 3]  ->  [0, 0, 9, 0, 0]
[0, 4, 0, 2]  ->  [0, 0, 0, 0]
```

- **Time:** `O(n)` — two passes over the array.
- **Space:** `O(1)` extra — the output array doubles as the prefix buffer; nothing else grows with `n`.

> Why two passes beat division: one `0` in the array would make the "divide the total" trick divide by zero.
> Prefix × suffix sidesteps it — with a single zero only that slot survives, and with two zeros every slot
> is zero.
