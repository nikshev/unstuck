# defi19 — Signature Replay

A payout vault pays `amount` to `to` whenever you present a message the **operator signed**. The bug:
the signed digest is only `keccak256(to, amount)` — **no nonce, no deadline, no domain, and nothing
marks a signature as used**. The signature is public in the transaction calldata, so anyone can
**replay it** again and again. One operator signature meant for a single 100-token payout is replayed
10× in one transaction and drains 1,000.

The fix: bind each signature — an **EIP-712 domain** (this contract + chain), a **nonce**, a
**deadline**, and a **used-digest guard** — so a valid signature pays exactly once and every replay
reverts with `used`.

## Reproduce it yourself

```bash
export RPC="https://your-sepolia-rpc-endpoint"
export PK="0xYOUR_FUNDED_SEPOLIA_PRIVATE_KEY"   # the deployer is the operator/signer
./reproduce.sh          # forge tests + all 3 acts, live on Sepolia
```

## Follow the tokens on Etherscan

The lab ERC-20 emits the standard `Transfer` event, so the drain shows its full **ERC-20 Tokens
Transferred** list. The attack tx —
[`0x59bb64…2d9ace`](https://sepolia.etherscan.io/tx/0x59bb64b48193b8566c4b2a5e354e2fb32396c7a356fcfcd038dc05e6e02d9ace)
— lists **ten identical transfers**, Vault → Attacker, 100 RWD each = **1,000 from a 100 authorization**.

## The exact transactions (Sepolia)

**Act 1 — honest**  · token `0x294d61c287D71f91145AAAEB5BfF3737A6A38262` · vault `0x1B79b2591a0a348e3eaDc3567E44b33F1Ba9B5e0`
- claim: [0x189c92…7e9e87](https://sepolia.etherscan.io/tx/0x189c927dbe02f77aecc1a29f3ef488ccaddc8321bf7440c0999b6937687e9e87) — Vault → Alice 100 RWD (the one authorized payout)

**Act 2 — attack (replay)**  · replayer `0xaAeb6831402a9333e9dB4E1d6671C3F2564B9eCd` · attacker `0x6813Eb9362372EEF6200f3b1dbC3f819671cBA69`
- drain: [0x59bb64…2d9ace](https://sepolia.etherscan.io/tx/0x59bb64b48193b8566c4b2a5e354e2fb32396c7a356fcfcd038dc05e6e02d9ace) — one signature replayed 10× → attacker 1,000 RWD, vault down 1,000

**Act 3 — fixed (domain + nonce + deadline + used)**  · token `0x5958094BbFC7086C23b8308f8341a4003950956d` · vault `0xddC0B7492A5D7048405B230BBD2007c5F95290d3`
- claim once: [0xccd986…b7b0d1](https://sepolia.etherscan.io/tx/0xccd9861e1ad5f15975f8ff45370dc5ba6451877ae307ed773d0f88cfe1b7b0d1) — 100 RWD, and the replay of that same signature reverts `used`

## Files
- `src/SignatureVault.sol` — the vulnerable vault (no nonce / used check)
- `src/SignatureVaultFixed.sol` — EIP-712 domain + nonce + deadline + used-guard
- `src/Replayer.sol` — replays one signature N times in a single atomic tx
- `src/MockERC20.sol` — the lab token; emits `Transfer` so the flow shows on Etherscan
- `test/SigReplay.t.sol` — the three acts as Foundry tests
- `script/*Sepolia.s.sol` — the on-chain deploys used above
