# DeFi Exploits, Explained — Ep 12: Read-Only Reentrancy

## 🎬 Watch

🔜 **Video coming soon.** [Subscribe on YouTube](https://www.youtube.com/channel/UC32d5uV5MEC1oMqVaVbQPNA) to catch it.

One of the sneakiest bugs in DeFi — and the one most developers get wrong. A vault adds the usual
reentrancy guard and feels safe, but a harmless-looking **`view`** function tells a lie at exactly the
wrong moment. Halfway through a withdrawal the vault has already sent the ETH but hasn't lowered its
share count yet, so its price reads at **half**. A second contract that trusts that price hands out
**twice** the shares, and the attacker redeems them at the true price for a clean profit — **+25 ETH,
straight out of the victim.**

## The idea in one test
`test/ROReentrancy.t.sol` builds a minimal version:
- `Vault` (VULNERABLE) — deposit ETH for shares; `withdraw()` sends ETH **before** it lowers `totalShares`; `pricePerShare()` is an **unguarded `view`**.
- `Seller` — sells its vault shares at whatever `pricePerShare()` reports. The victim.
- `Attacker` — `pwn()` deposits, withdraws, and in the ETH-receive callback (fired **mid-withdraw**, while the price reads half) buys cheap shares from the `Seller`, then redeems them at the true price.
- `VaultFixed` — the one-line fix: `require(!_lock)` in `pricePerShare()`, so the mid-withdraw read reverts.

`test_drain` proves the profit (`attacker in 100` → `attacker out 125`); `test_fixed_blocksIt` proves
the guarded vault reverts the same attack.

> The `nonReentrant` guard only protects the **writes**. The classic mistake is leaving the **view**
> unguarded — an outside contract can read your half-updated state and be tricked by it.

## Run it yourself
Requires [Foundry](https://getfoundry.sh).

```bash
forge install foundry-rs/forge-std   # first time only
forge test -vvv
```

You'll see `[PASS] test_drain` (the seller is robbed for 25 ETH) and `[PASS] test_fixed_blocksIt`
(the attack reverts on the price guard).

## Proven on Sepolia
Both vaults were deployed to the Sepolia testnet (at 0.1-ETH scale — the same 100→125 ratio) and hit
with the **same** attack:

| Vault | Attacker | Attack tx | Result |
|---|---|---|---|
| Vulnerable | `0x5F306fD2522A4e8d73477647c833Fe2e6C5486FE` | [`0x722d…b7e5`](https://sepolia.etherscan.io/tx/0x722d67befc01b86404b55864e21af66e9d7f91f3e5e35dd781b7f96b21e4b7e5) | ✅ Success — 0 → 0.125 ETH (+0.025 from the seller) |
| Fixed (guarded view) | `0x165B984DE1c379cDdeA30E134a2A0C3C73f2f44A` | [`0xc9aa…c850`](https://sepolia.etherscan.io/tx/0xc9aa2dee058864db81b0bfd1760ad74b6fc8f919647351a0fbb536f06d5fc850) | ❌ Fail — `execution reverted` |

## Key idea
- A reentrancy guard protects the function that **writes** — it does nothing for a `view` read in the same transaction.
- Mid-call, state is **half-updated**, so a getter returns a number that's briefly wrong.
- Fix: **guard the getter too** (`require(!_lock)`), or finish **every** state change before you ever hand control to an outsider (checks-effects-interactions).
- A value you can read at the wrong moment is a value someone can weaponise.

## Sources
- Read-only reentrancy explained (ChainSecurity, 2022): https://chainsecurity.com/heartbreaks-curve-lp-oracles/
- dForce read-only reentrancy (Feb 2023): https://rekt.news/dforce-rekt-2/
- Solidity security considerations (reentrancy, checks-effects-interactions): https://docs.soliditylang.org/en/latest/security-considerations.html
- Foundry: https://getfoundry.sh
