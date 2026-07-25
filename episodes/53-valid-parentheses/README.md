# Valid Parentheses (LeetCode 20) — in Rust

Given a string of only `( ) [ ] { }`, decide if every bracket is closed by the correct type in the
correct order. The rule — "a closer must match the **most recent** unmatched opener" — is exactly a
**stack** (LIFO): push each opener; on a closer, pop the top and check it matches. Wrong pop or a
non-empty stack at the end ⇒ invalid. One pass, O(n) time / O(n) space.

## Run
```
cargo run
```
Prints all six cases: `"()"→true`, `"()[]{}"→true`, `"(]"→false`, `"([])"→true`, `"([)]"→false`, `"(("→false`.
