# defi20 — Classic Reentrancy (The DAO)

An ETH vault lets you `deposit` and `withdraw`. The bug: `withdraw()` **sends the ETH with an external
call BEFORE it zeroes your recorded balance**. That external call runs the receiver's `receive()`
mid-withdrawal, while the balance still reads full — so a malicious contract **re-enters** `withdraw()`
again and again and drains the whole vault. This is the exact bug that drained **The DAO ($60M, 2016)**
and forced the Ethereum fork.

The fix: **Checks-Effects-Interactions** — zero the balance *before* the external call — plus a simple
**reentrancy lock**. A re-entrant call then finds a zero balance and does nothing.

## Reproduce it yourself

```bash
export RPC="https://your-sepolia-rpc-endpoint"
export PK="0xYOUR_FUNDED_SEPOLIA_PRIVATE_KEY"
./reproduce.sh          # forge tests + all 3 acts, live on Sepolia
```

## Follow the value on Etherscan (Internal Transactions)

Classic reentrancy moves **ETH**, so the drain shows on the attack tx's **Internal Transactions** tab
(not ERC-20 transfers). The attack tx —
[`0xbb8264…d20769`](https://sepolia.etherscan.io/tx/0xbb82646d276fdfdd0b41e1d4cb49b71948c44b9658d0f7e937df86b532d20769)
— lists **1 deposit + 6 recursive `Vault → Attacker` sends of 0.01 ETH each** (the nested Trace
Address `call_0_1_1_1…` *is* the recursion): **0.01 ETH in → 0.06 ETH out**, the whole vault drained.

## The exact transactions (Sepolia)

**Act 1 — honest**  · vault `0x30f0a668dBc982fA77bbf350A5d0003307Ce2EE1`
- deposit 0.03, then withdraw: [0x3524d0…29c59a](https://sepolia.etherscan.io/tx/0x3524d0ebd50b59fd31b8ff04d3398d6ea643d938d6ebfceb275c0cb48229c59a) — one internal `Vault → user` send

**Act 2 — attack (reentrancy)**  · vault `0x4dd5412cA2069D03904c1c9893f398Bb5C3fA91c` · attacker `0xA92f0753708513Dd7FD69Be99A0ac5c570517A48`
- attack: [0xbb8264…d20769](https://sepolia.etherscan.io/tx/0xbb82646d276fdfdd0b41e1d4cb49b71948c44b9658d0f7e937df86b532d20769) — 6 re-entrant withdrawals → attacker 0.06, vault 0

**Act 3 — fixed (CEI + lock)**  · vault `0x03059293EBb05920e4DfE79f0a9138AaC4E48dfF` · attacker `0xC5D7EDfED58c5652F380F55f24F3e509a0468390`
- same attack: [0x819b25…27a101](https://sepolia.etherscan.io/tx/0x819b2538e2dc7ba40c7e3a024005b927d5ce9821eaaff77afedf8775c927a101) — attacker gets only its own 0.01 back, vault keeps 0.05

## Files
- `src/Vault.sol` — the vulnerable vault (send before zeroing)
- `src/VaultFixed.sol` — Checks-Effects-Interactions + a reentrancy lock
- `src/Attacker.sol` — deposits 1 unit, then re-enters `withdraw()` to drain
- `test/Reentrancy.t.sol` — the three acts as Foundry tests
- `script/*Sepolia.s.sol` — the on-chain deploys used above
