# 0xUnstuck

> web3 dev things — the stuff nobody documents.

Runnable code companions for the [0xUnstuck](https://youtube.com/@0xunstuck) videos.
Each episode is a short, self-contained project: clone it, run it, watch the bug happen,
then watch the fix.

## Episodes

| #  | Topic | Video | Code |
|----|-------|-------|------|
| 01 | Solana "Blockhash not found" — why it happens & the 2-line fix | _(soon)_ | [episodes/01-blockhash-not-found](episodes/01-blockhash-not-found) |

## How to use

```bash
git clone git@github.com:nikshev/unstuck.git
cd unstuck/episodes/01-blockhash-not-found
npm install
npm run setup      # creates a throwaway devnet wallet + airdrops test SOL
npm run reproduce  # see the bug
npm run fix        # see the fix
```

Every episode targets **devnet** and uses a throwaway keypair — never put real funds in it.

## Support

If these help you:

- **SOL / USDC (Solana):** `3bQPvjmVr2hXdZuzByxmoo3kwkjUwTdnerUUDYUweF2K`
- **Ko-fi:** https://ko-fi.com/0xunstuck

## License

MIT — see [LICENSE](LICENSE).
