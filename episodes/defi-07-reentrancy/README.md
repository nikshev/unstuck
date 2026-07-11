# DeFi #7 — Reentrancy (Stars-Arena-class, ~$3M, 2023)

## 🎬 Watch

[![Watch on YouTube](https://img.youtube.com/vi/CLNUqUDjee0/maxresdefault.jpg)](https://youtu.be/CLNUqUDjee0)

▶️ **Watch: https://youtu.be/CLNUqUDjee0**


> **Illustrative reconstruction** for education — a minimal teaching model of the flaw,
> **not** the real bytecode. Do not deploy to mainnet.

📺 Video: **It Paid You Before It Marked You Paid ($3M Reentrancy)**

## The bug ([`vulnerable.sol`](vulnerable.sol))
A vault's `withdraw()` **sent the ETH before zeroing the balance**. Sending ETH to a contract runs
its `receive()`, and the attacker's `receive()` calls `withdraw()` **again** — the balance still
isn't zeroed, so the vault pays a second time, then a third… draining the whole shared pool in one
transaction. The attacker deposits 1, walks away with everything.

## The fix ([`fixed.sol`](fixed.sol))
**Checks-Effects-Interactions**: zero the balance *before* the external call. On re-entry the balance
is already 0, so `require(amt > 0)` fails and the whole thing reverts. (A reentrancy guard / lock is
a good belt-and-suspenders too.)

## Run the proof
```bash
forge install foundry-rs/forge-std
forge test -vv
```
- `test_OLD_Reentrancy_DrainsVault` — vault 3 → 0, attacker loot 4 (for a 1 ETH deposit)
- `test_FIXED_Reentrancy_Reverts` — same attack reverts, vault untouched

[`src/ReentrancyDemo.sol`](src/ReentrancyDemo.sol) is the click-to-run demo used in the video (Remix)
and deployed to Sepolia (deploy with a Value of 4 ether).

## Live on Sepolia (Etherscan-verified)
- Vulnerable — https://sepolia.etherscan.io/address/0x5FDb02df5388E90cee50de06aa49BF3be852d1a4#code
- Fixed — https://sepolia.etherscan.io/address/0xb2d9Fb4dC9Ce5dFb31806B9eb6fe23Cbeca32CD3#code
- 💀 Drain tx — https://sepolia.etherscan.io/tx/0xc5bafdc4ed41305941b63b08b6be2ce85d2076123f09268984f33ca1494646ff
- ✅ Fixed reverts — https://sepolia.etherscan.io/tx/0xad49e1a7bda76d7b3a23ef0dd9fc682cc63cc6a9d84f62c7fed4134029e5d42a

## Takeaway
Update state **before** any external call (checks → effects → interactions). Any call that sends ETH
can hand control back to the receiver, who can re-enter. Read every external call as: "what if they
call me again right here?"

## Verified sources
- Real incident: Stars Arena (Avalanche, ~$3M, Sep 2023) — reentrancy in `sellShares`
- Attack tx (Avalanche) — https://snowtrace.io/tx/0x49c5b3b414bf874689de9a5b98c55445659c2fd2ad6f8a3cdd4e0203937c395e
- DeFiHackLabs Incident Explorer — https://defihacklabs.io/explorer/index.html
