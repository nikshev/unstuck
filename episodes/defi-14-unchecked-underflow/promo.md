# Promo — DeFi #14: `unchecked` Underflow

## X / Twitter thread
1/ A vault drained by ONE word: `unchecked`.

An attacker deposited $1 of dust, subtracted a bigger fee, and their balance wrapped to a 60-digit number. Then they redeemed the whole pool. Rebuilt from scratch 🧵

2/ Since Solidity 0.8, math reverts on over/underflow automatically — for free. The 2018 overflow bugs were supposed to be dead.

But there's an escape hatch: `unchecked { }`. It turns the safety back off to save a little gas.

3/ Our vault tracks each user's `credit`. The whole bug is one line in `settle`:

```
unchecked { credit[msg.sender] -= fee; }
```

Deposit 1 → credit = 1. Call settle with fee = 2. `1 - 2` doesn't revert — it WRAPS to ~2^256.

4/ Now credit is astronomically huge, so `redeem(101)` sails past `require(credit >= amount)` and the vault pays out everything — 100 WETH of other users' money + the attacker's $1 of dust.

A dollar drained the pool.

5/ The fix is deleting one word: take the subtraction OUT of `unchecked`. Checked math is back; settle with fee > credit now reverts. No wrap, no drain.

`unchecked` is a loaded gun — only point it at math you can PROVE can't overflow.

6/ This is a simplified rebuild of the Flooring Protocol hack (Ethereum, June 2026, ~$900K) — two accounting paths, a fake "ghost-ownership" NFT ID, two unchecked underflows.

Full code + Foundry test + a live Sepolia proof (drain Succeeds, fix reverts):
https://github.com/nikshev/unstuck/tree/main/episodes/defi-14-unchecked-underflow

Full walkthrough on YouTube: @0xUnstuck

## Reddit (r/ethdev, r/defi) — educational
**Rebuilt the `unchecked` underflow class in Foundry (dust deposit → 2^256 credit → drained vault, one-word fix, Sepolia proof)**

Solidity 0.8 reverts on over/underflow for free — until a dev wraps a subtraction in `unchecked` to save gas. Here a vault's `settle(fee)` does `credit -= fee` inside `unchecked`; an attacker deposits 1 wei of credit, settles a fee of 2, and `1 - 2` wraps to ~2^256, so `redeem` drains the whole pool.

Minimal reconstruction (a WETH mock + a claim vault + the fixed vault) with a Foundry test that prints the wrapped credit and the before/after ledger, plus both sides deployed + hit on Sepolia (redeem Succeeds on the vulnerable vault, settle reverts on the fixed one). Inspired by the June 2026 Flooring Protocol hack (~$900K). Code + walkthrough in the link. Educational only — everything runs locally / on testnet.
