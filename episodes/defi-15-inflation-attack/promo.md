# Promo — DeFi #15: The First-Depositor Inflation Attack

## X / Twitter thread
1/ The first person to deposit into a vault can rob the second. Deposit 1 wei, "donate" 100 ETH, and the next person's 100-ETH deposit mints them ZERO shares — which you redeem for the whole pot. Rebuilt in Foundry + proven on Sepolia 🧵

2/ A vault gives you SHARES for your deposit: shares = assets × totalShares / totalAssets. The first depositor sets the price. And that division rounds DOWN. Hold onto that.

3/ Attacker deposits 1 wei → owns the whole vault (1 share). Then transfers 100 WETH straight in — no deposit call, just a raw transfer. Now 1 share ≈ 100 WETH. Still just 1 share outstanding.

4/ Victim deposits 100 WETH. Their shares = 100 × 1 / 100 → rounds to 0. They own NOTHING. Attacker redeems their 1 share → 200 WETH. Profit: the victim's entire 100 WETH.

5/ The fix (OpenZeppelin ERC-4626): VIRTUAL shares + assets. Pretend the vault always holds a little phantom liquidity, so a donation can't move the price. Victim now mints ~1,999 shares. Attack dead.

6/ All three steps ran as real txs on Sepolia — donate, victim (0 shares), redeem (200 WETH) — every field verifiable on Etherscan. Full code + line-by-line breakdown 👇
https://github.com/nikshev/unstuck/tree/main/episodes/defi-15-inflation-attack
