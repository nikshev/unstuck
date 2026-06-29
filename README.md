# 0xUnstuck

> web3 dev things + Rust coding challenges — the stuff nobody documents.

Runnable code companions for the [0xUnstuck](https://youtube.com/@0xunstuck) videos.
Each episode is short and self-contained: clone it, run it, see the point.

## Episodes

| #  | Topic | Stack | Code |
|----|-------|-------|------|
| 01 | Solana "Blockhash not found" — the 2-line fix | Node | [episodes/01-blockhash-not-found](episodes/01-blockhash-not-found) |
| 02 | Solana "TokenAccountNotFoundError" — send SPL tokens right | Node | [episodes/02-token-account-not-found](episodes/02-token-account-not-found) |
| 03 | Two Sum — O(n) hash map | Rust | [episodes/03-two-sum](episodes/03-two-sum) |
| 04 | Merge Sort — O(n log n) | Rust | [episodes/04-merge-sort](episodes/04-merge-sort) |
| 05 | FizzBuzz — done right | Rust | [episodes/05-fizzbuzz](episodes/05-fizzbuzz) |
| 06 | Fix a Git Merge Conflict | git | [episodes/06-git-merge-conflict](episodes/06-git-merge-conflict) |

## Running an episode

**Node episodes (01–02):**
```bash
cd episodes/01-blockhash-not-found
npm install && npm run setup && npm run reproduce && npm run fix
```

**Rust episodes (03–05):** need the [Rust toolchain](https://rustup.rs).
```bash
cd episodes/03-two-sum
cargo run --release --bin brute
cargo run --release --bin optimal
```

**Git episode (06):** see its README for the practice script.

## Support

- **SOL / USDC (Solana):** `3bQPvjmVr2hXdZuzByxmoo3kwkjUwTdnerUUDYUweF2K`
- **Ko-fi:** https://ko-fi.com/0xunstuck

## License

MIT — see [LICENSE](LICENSE).
