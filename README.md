# 0xUnstuck

> web3 dev things + Rust coding challenges — the stuff nobody documents.

Runnable code companions for the [0xUnstuck](https://youtube.com/@0xunstuck) videos.
Each episode is short and self-contained: clone it, run it, see the point.

## Playlists
- **Rust Coding Challenges** — episodes 03, 04, 05, 07, 08, 09, 11, 12, 13, 15, 16, 17
- **Dev Errors, Fixed** — episodes 01, 02, 06, 10, 14, 18

## Episodes

| #  | Topic | Stack | Code |
|----|-------|-------|------|
| 01 | Solana "Blockhash not found" — the 2-line fix | Node | [episodes/01-blockhash-not-found](episodes/01-blockhash-not-found) |
| 02 | Solana "TokenAccountNotFoundError" | Node | [episodes/02-token-account-not-found](episodes/02-token-account-not-found) |
| 03 | Two Sum — O(n) hash map | Rust | [episodes/03-two-sum](episodes/03-two-sum) |
| 04 | Merge Sort — O(n log n) | Rust | [episodes/04-merge-sort](episodes/04-merge-sort) |
| 05 | FizzBuzz — done right | Rust | [episodes/05-fizzbuzz](episodes/05-fizzbuzz) |
| 06 | Fix a Git Merge Conflict | git | [episodes/06-git-merge-conflict](episodes/06-git-merge-conflict) |
| 07 | Valid Parentheses — the stack | Rust | [episodes/07-valid-parentheses](episodes/07-valid-parentheses) |
| 08 | Binary Search — bug-free template | Rust | [episodes/08-binary-search](episodes/08-binary-search) |
| 09 | Contains Duplicate — HashSet | Rust | [episodes/09-contains-duplicate](episodes/09-contains-duplicate) |
| 10 | Fix "Cannot read properties of undefined" | JS | [episodes/10-cannot-read-undefined](episodes/10-cannot-read-undefined) |
| 11 | Reverse a Linked List — in-place | Rust | [episodes/11-reverse-linked-list](episodes/11-reverse-linked-list) |
| 12 | Quicksort + the O(n²) trap | Rust | [episodes/12-quicksort](episodes/12-quicksort) |
| 13 | Valid Anagram — O(n) char counts | Rust | [episodes/13-valid-anagram](episodes/13-valid-anagram) |
| 14 | Fix "Port 3000 already in use" (EADDRINUSE) | Node | [episodes/14-port-in-use](episodes/14-port-in-use) |

| 15 | Climbing Stairs — DP from scratch | Rust | [episodes/15-climbing-stairs](episodes/15-climbing-stairs) |
| 16 | Bubble Sort — honest verdict | Rust | [episodes/16-bubble-sort](episodes/16-bubble-sort) |
| 17 | Group Anagrams — canonical key | Rust | [episodes/17-group-anagrams](episodes/17-group-anagrams) |
| 18 | Fix the CORS error (the right way) | Node | [episodes/18-cors](episodes/18-cors) |

## Running an episode
- **Rust** (needs [rustup](https://rustup.rs)): `cd episodes/<ep> && cargo run --release --bin <name>`
- **Node**: `cd episodes/<ep> && node <file>.js` (episode 01/02: `npm install` first)
- **Git** (06): see its README for the practice script.

## Support
- **SOL / USDC (Solana):** `3bQPvjmVr2hXdZuzByxmoo3kwkjUwTdnerUUDYUweF2K`
- **Ko-fi:** https://ko-fi.com/0xunstuck

## License
MIT — see [LICENSE](LICENSE).
