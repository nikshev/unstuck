# DeFi #10 — Signature Replay (KiloEx-class signature bug, ~$8.4M, 2025)

## 🎬 Watch

🔜 **Video coming soon.** [Subscribe on YouTube](https://www.youtube.com/channel/UC32d5uV5MEC1oMqVaVbQPNA) to catch it.


> **Illustrative reconstruction** for education — a minimal teaching model of the flaw,
> **not** the real bytecode. Do not deploy to mainnet.

📺 Video: **One Signature, Drained a Hundred Times (Signature Replay)**

## The bug ([`vulnerable.sol`](vulnerable.sol))
A vault pays out whatever a trusted **signer** approves, proven by an ECDSA signature. `claim()`
checks the signature is **valid** with `ecrecover` — but never records that a signature was **used**.
So the attacker submits the *exact same signature* again and again, and the vault pays every time:
one approval drains the whole pool.

## The fix ([`fixed.sol`](fixed.sol))
Record each signature's fingerprint and reject it on the second use (`require(!used[sigId])` + mark
it used). In production, prefer a **per-account nonce** and **EIP-712** typed data bound to the
chain id, contract, and a **deadline**, so a signature can't be replayed elsewhere or after expiry.

## Run the proof
```bash
forge install foundry-rs/forge-std
forge test -vv
```
- `test_OLD_SignatureReplay_DrainsPool` — 1 legit claim (pool 900), replay the same sig (pool 800), drain the rest (pool **0**, loot **1000**)
- `test_FIXED_SignatureReplay_Reverts` — same attack, the replay **reverts** ("signature already used"), pool intact

[`src/SigReplayDemo.sol`](src/SigReplayDemo.sol) is the click-to-run demo (Remix) and the Sepolia deploy.

## Live on Sepolia (Etherscan-verified)
- Vulnerable (Attacker_OLD) — `0xDbECFcD3EAEb3701C9268bDAE37B54144Fd57E4e`
- Fixed (Attacker_NEW) — `0x87222248f70cAee2B21a9091c225c5AC9BdA3ddc`
- 💀 Drain tx (Call Drain → Success) — `0x81c4cd10c434b32819cb191560480fa3d3a4c853764ce457e9bcf09f86a7c46f`
- ✅ Fixed reverts (replay → Fail) — `0xfeb097033b536379e8be962cfccf485e324fe6bf3d277c96341cad9b37cdb128`

## The lesson
A valid signature proves *approval*, not *only once*. Track used signatures (or a nonce), and bind
them with EIP-712. Real incident: **KiloEx** (~$8.4M, Base/BNB, Apr 2025) — a broken meta-tx
forwarder trusted a signature without binding it to the right signer.

⚠️ Educational / not financial advice. Genericised — the lesson, not the names.
