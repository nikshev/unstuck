# DeFi #1 — TrustedVolumes RFQ Drain (~$5.87M, 2026)

> **Illustrative reconstruction** for education — a minimal teaching model of the two flaws,
> **not** the real bytecode. Do not deploy.

📺 Video: _(soon)_

## The two flaws ([`vulnerable.sol`](vulnerable.sol))
1. **Open registration** — `registerAllowedOrderSigner` has no access control, so anyone can
   register their own key as a trusted signer.
2. **Wrong party checked** — `fillOrder` validates the signer against `order.taker` but pulls
   funds via `transferFrom(order.maker, …)`. Authorization and the debited account differ, so an
   attacker who is the taker and trusts their own signer drains any maker with an active approval.

## The fix ([`fixed.sol`](fixed.sol))
- `onlyOwner` on the signer registry (close the open door).
- Validate the signer against **`order.maker`** — the account whose funds move.
- Replay guard (mark each order used) + EIP-712 typed-data signatures.

## Takeaway
Check permission against the account being **debited**. "Authorised by X, paid by Y" is always a bug.

## Verified sources
- DarkNavy — https://www.darknavy.org/web3/exploits/trustedvolumes-rfq-proxy-drain/
- Verichains — https://blog.verichains.io/p/trustedvolumes-exploit-analysis
- Rekt — https://rekt.news/trustedvolumes-rekt
- Attack tx `0xc5c61b3ac39d854773b9dc34bd0cdbc8b5bbf75f18551802a0b5881fcb990513` · Proxy `0xeeeeee53033f7227d488ae83a27bc9a9d5051756`
