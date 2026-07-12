# Promo — DeFi #11: Flash-Loan Governance Takeover

## X / Twitter thread
1/ You can steal a DeFi treasury without hacking anything.

Borrow the governance token for 15 seconds. Vote yourself the treasury. Repay. One transaction.

This is the Beanstalk attack (~$182M). Here's how it works, rebuilt from scratch 🧵

2/ Two ingredients:
• On-chain governance — votes = your token balance
• Flash loans — borrow millions, no collateral, if you repay in the same tx

The bug: voting counts the tokens you hold RIGHT NOW.

3/ So the attacker, in one tx:
→ flash-borrows the majority of the gov token
→ proposes "send the treasury to me"
→ votes with the borrowed tokens
→ executes → treasury drained
→ repays the loan

The votes existed for microseconds. They counted anyway.

4/ The fix is basically one line: a timelock. Propose and execute can't be in the same block.

A flash loan dies at the end of its transaction — so its votes are worthless a block later.

5/ Full code + a Foundry test that drains a treasury and then blocks the attack, plus a live Sepolia proof (success vs fail on Etherscan):
https://github.com/nikshev/unstuck/tree/main/episodes/defi-11-flashloan-governance

Full walkthrough on YouTube: @0xUnstuck

## Reddit (r/ethdev, r/defi) — educational
**Rebuilt the Beanstalk-class flash-loan governance attack in Foundry (drain + one-line fix + Sepolia proof)**

Minimal contracts: a gov token with a flash loan, a governance that counts votes by current balance, and an attacker that borrows the majority, votes itself the treasury, drains it, and repays — all in one tx. `forge test` drains a 100-ETH treasury; the fixed (timelock) version reverts the same attack. Deployed both to Sepolia and hit each with the same tx: vulnerable = Success, fixed = Fail. Code + Etherscan links inside. Educational, testnet only.
