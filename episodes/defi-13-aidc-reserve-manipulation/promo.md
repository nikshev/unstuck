# Promo — DeFi #13: AIDC Reserve Manipulation

## X / Twitter thread
1/ A token that got drained by its own burn function.

AIDC's burn didn't take tokens from the seller — it took them from the **liquidity pool**. Every burn made AIDC more "valuable" out of thin air. ~$121K gone. Rebuilt from scratch 🧵

2/ Background: AIDC was a fee-on-transfer token. A burn is supposed to destroy the SELLER's tokens. AIDC's `executeAccumulatedBurn` instead did `balanceOf[pair] -= amount` — burning coins out of the AMM pool — then called `pair.sync()`.

3/ `sync()` re-reads the pool's real balances into its price reserves. So after the burn, the pair sees far less AIDC beside the same WBNB. By x*y=k, AIDC's price spikes — with no trade at all.

Do it repeatedly and the price prints as high as you like.

4/ Then the attacker swaps their cheap AIDC into the now-overpriced pool and pulls out the real money (WBNB). On a fair 100 WBNB / 1,000,000 AIDC pool: burn 990k → reserve 10k (AIDC ×100) → swap 10k AIDC → 50 WBNB out. Half the pool.

5/ The fix is two lines: a burn can only touch `msg.sender`'s balance (checked), and it must never call `sync()` on the AMM. Burn your own coins; leave the pool alone.

6/ Full code + a Foundry test with a step-by-step reserve ledger, plus a live Sepolia proof (the attack Succeeds on the vulnerable token, Fails/reverts on the fixed one):
https://github.com/nikshev/unstuck/tree/main/episodes/defi-13-aidc-reserve-manipulation

Full walkthrough on YouTube: @0xUnstuck

## Reddit (r/ethdev, r/defi) — educational
**Rebuilt the AIDC reserve-manipulation hack in Foundry (burn-from-pool + sync → drain, two-line fix, Sepolia proof)**

AIDC (BNB Chain, ~$121K) had a fee/burn bug: `_executeAccumulatedBurn` burned tokens out of the Pancake pair's balance instead of the seller, then called `sync()`, deflating the AIDC reserve so the price spiked with no trade. The attacker looped it, then swapped cheap AIDC for the pool's WBNB.

Minimal reconstruction (token + a constant-product pair + the fix) with a Foundry test that prints the reserve ledger as it drains, and both sides deployed + hit on Sepolia (Success vs reverted). Code + walkthrough in the link. Educational only — everything runs locally / on testnet.
