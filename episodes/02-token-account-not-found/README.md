# 02 — Solana "TokenAccountNotFoundError"

> You send an SPL token and your code throws **`TokenAccountNotFoundError`**. Your token and
> balance are fine — the recipient just has no token account yet. Here's why, and the one-call fix.

📺 Video: _(link soon)_

## The problem

On Solana, a wallet **doesn't hold tokens directly**. Each token lives in its own
**Associated Token Account (ATA)** — one per wallet, per mint. If the recipient has never held
this particular token, that account simply **doesn't exist yet**.

[`reproduce.js`](reproduce.js) derives the recipient's ATA address and then assumes it exists —
it calls `getAccount()` before sending, which throws:

```
FAILED: TokenAccountNotFoundError
```

Deriving the address is just math (a PDA); it creates nothing. The account has to be **created and
rent-funded** before it can receive a single token.

## The fix (one call)

```js
// instead of assuming the recipient's token account exists:
const dest = await getOrCreateAssociatedTokenAccount(conn, payer, mint, recipient);
//            ^ creates it if missing; `payer` covers the ~0.002 SOL rent
await transfer(conn, payer, source, dest.address, payer, amount);
```

See [`fix.js`](fix.js). `getOrCreateAssociatedTokenAccount` creates the recipient's account when it's
missing, then you transfer as normal.

> **Gotcha — Token-2022:** there are two token programs (classic **Token** and **Token-2022**).
> Derive and create the ATA with the **same program ID the mint uses**, or you'll get this error even
> when the account exists. Inside a single transaction, prefer the **idempotent** create instruction
> (`createAssociatedTokenAccountIdempotentInstruction`).

## Run it

```bash
npm install
npm run wallet     # creates throwaway.json (devnet) + airdrops test SOL
npm run setup      # creates a token mint + a fresh recipient with no ATA
npm run reproduce  # -> FAILED: TokenAccountNotFoundError
npm run fix        # -> OK sent 10 tokens: <signature>
```

Targets **devnet** with throwaway keypairs (`throwaway.json`, `recipient.json` — both git-ignored).
Never use real funds.
