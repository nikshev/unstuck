# DeFi #6 — Arbitrary Call (SwapNet-class, ~$13.4M, 2026)

> **Illustrative reconstruction** for education — a minimal teaching model of the flaw,
> **not** the real bytecode. Do not deploy to mainnet.

📺 Video: **One Function Let Strangers Spend Your Tokens ($13.4M)**

## The bug ([`vulnerable.sol`](vulnerable.sol))
A DEX-aggregator router had `execute(target, data)` that made an **arbitrary low-level call as the
router** — with no check on `target`. Because users had **approved** the router (normal for any DEX),
an attacker called `execute(token, transferFrom(victim, attacker, amount))`. The token saw its
trusted router asking and moved the victim's tokens. Repeat for everyone who ever approved it.

## The fix ([`fixed.sol`](fixed.sol))
`require(allowed[target])` before the call — the owner whitelists the small set of contracts the
router may ever touch. An attacker's chosen token isn't on it, so the arbitrary call reverts.

## Run the proof
```bash
forge install foundry-rs/forge-std
forge test -vv
```
- `test_OLD_ArbitraryCall_DrainsVictim` — victim 1,000,000 → 0, attacker → 1,000,000 (drain)
- `test_FIXED_ArbitraryCall_Reverts` — same attack reverts `"target not allowed"`, victim intact

[`src/ArbDemo.sol`](src/ArbDemo.sol) is the click-to-run demo used in the video (Remix) and deployed to Sepolia.

## Live on Sepolia (Etherscan-verified)
- Vulnerable — https://sepolia.etherscan.io/address/0x144aB767432e0eb15A275109B1BD79Dde8081eb4#code
- Fixed — https://sepolia.etherscan.io/address/0x1D92D40f0C2E5c48f1B46b83400539AE2A77fd5D#code
- 💀 Drain tx — https://sepolia.etherscan.io/tx/0xc140bfd081a6c905aafb44eeef36900dfd206df3a681142345a37ce587817450
- ✅ Fixed reverts — https://sepolia.etherscan.io/tx/0xa63a37008f5718c378453c6973982014e8600929747d8aae2fccfcd5bd363a46

## Takeaway
A contract's calls inherit **its** trust (approvals, roles). An arbitrary call is arbitrary power —
whitelist targets, and never forward user-controlled `(target, data)` that can move funds.

## Verified sources
- BlockSec — https://blocksec.com/blog/17m-closed-source-smart-contract-exploit-arbitrary-call-swapnet-aperture
- Real attack tx (Arbitrum) — https://arbiscan.io/tx/0x25c08b3882ade18cbbda81521afff7239c0e91d050f6c178968802cb1b2e2b04
- DeFiHackLabs Incident Explorer — https://defihacklabs.io/explorer/index.html
