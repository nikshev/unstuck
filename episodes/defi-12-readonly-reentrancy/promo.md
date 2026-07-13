# Promo — DeFi #12: Read-Only Reentrancy

## X / Twitter thread
1/ You added a reentrancy guard. You're still not safe.

A `view` function — the kind that just returns a price — can be read at exactly the wrong moment and lie. That lie drains a protocol. This is read-only reentrancy, rebuilt from scratch 🧵

2/ The setup: a vault where you deposit ETH for shares. `withdraw()` sends your ETH FIRST, then lowers the share count. Standard `nonReentrant` guard on it. Feels fine.

The catch: `pricePerShare()` is a `view` — and it's NOT guarded.

3/ Mid-withdraw, the vault has already sent the ETH but hasn't dropped the share count yet. So for one instant its books say: half the money, same shares → price reads at HALF.

The vault's own ETH-send hands control to the attacker at exactly that instant.

4/ In that window the attacker buys vault shares from a Seller that trusts `pricePerShare()`. Half price → twice the shares. The withdraw finishes, price snaps back, and the attacker redeems those shares at the true price.

Paid 25, got 50. +25 ETH, out of the Seller.

5/ The fix is one line: guard the VIEW too. `require(!_lock)` in `pricePerShare()`, so a mid-withdraw read reverts.

The rule: a reentrancy guard protects your writes — an unguarded view exposes your half-updated state to the whole chain.

6/ Full code + a Foundry test that robs the seller and then blocks the attack, plus a live Sepolia proof (Success vs Fail on Etherscan):
https://github.com/nikshev/unstuck/tree/main/episodes/defi-12-readonly-reentrancy

Full walkthrough on YouTube: @0xUnstuck

## Reddit (r/ethdev, r/defi) — educational
**Rebuilt read-only reentrancy in Foundry (rob a seller + one-line fix + Sepolia proof)**

Minimal contracts: a vault whose `withdraw()` sends ETH before lowering `totalShares`, an unguarded `pricePerShare()` view, and a Seller that prices shares off that view. Mid-withdraw the price reads at half, so the attacker's callback buys 2× the shares from the seller and redeems them at the true price — `forge test` shows the attacker go from 100 to 125 ETH. The fixed vault guards the view (`require(!_lock)`) and the same attack reverts. Deployed both to Sepolia and hit each with the same tx: vulnerable = Success (0 → 0.125 ETH), fixed = Fail (execution reverted). Code + Etherscan links inside. Educational, testnet only.

## dev.to / Hashnode
**Read-Only Reentrancy: how a `view` function drains a protocol (with a Foundry PoC + fix)**
_(embed the video · tags: solidity, security, ethereum, defi)_
Walkthrough of the whole bug class: why `nonReentrant` on withdraw isn't enough, how a getter read mid-call returns half-updated state, and the one-line fix. Reproduced end to end in Foundry and proven on Sepolia.
