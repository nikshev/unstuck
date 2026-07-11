# 01 — Solana "Blockhash not found"

## 🎬 Watch

[![Watch on YouTube](https://img.youtube.com/vi/x73cikwFZTU/maxresdefault.jpg)](https://youtu.be/x73cikwFZTU)

▶️ **Watch: https://youtu.be/x73cikwFZTU**


> Your transaction fails with **`Transaction simulation failed: Blockhash not found`** — here's
> why it happens and the two-line fix.

📺 Video: _(link soon)_

## The problem

Every Solana transaction must reference a **recent blockhash**. It proves freshness and prevents
replays — but a blockhash is only valid for about **150 slots (~60–90 seconds)**. Hold onto it too
long before sending, and the validator no longer has a record of it, so it rejects the transaction
before it's even processed.

[`reproduce.js`](reproduce.js) makes this happen on purpose: it fetches a blockhash, builds a
self-transfer, **waits 95 seconds**, then sends — and blows up with `Blockhash not found`.

## The fix (two lines)

```js
// 1) fetch the blockhash RIGHT BEFORE you send — not earlier
const { blockhash, lastValidBlockHeight } = await conn.getLatestBlockhash();

// 2) confirm against the SAME window
await conn.confirmTransaction({ signature: sig, blockhash, lastValidBlockHeight }, 'confirmed');
```

See [`fix.js`](fix.js). Fetch late, send now, confirm with `lastValidBlockHeight`.

You don't have to literally `sleep` to hit this — the same thing happens if you cache a blockhash
and reuse it, build transactions far ahead of sending, or sit on a wallet approval popup. Slow
signing is the number-one real-world cause.

> **Bonus:** if you genuinely need a transaction valid for minutes or hours (offline/HFT), don't
> fight the expiry — use a [durable nonce](https://solana.com/developers/courses/offline-transactions/durable-nonces).

## Run it

```bash
npm install
npm run setup      # creates throwaway.json (devnet) + airdrops test SOL
npm run reproduce  # -> FAILED: Blockhash not found
npm run fix        # -> OK confirmed: <signature>
```

Targets **devnet** with a throwaway keypair (`throwaway.json`, git-ignored). Never use real funds.
