# Promo — DeFi #16: Flash-Loan Price-Oracle Manipulation

## X / Twitter thread
1/ A lending pool priced your collateral off ONE DEX pool's live spot price. So I flash-borrowed $1M, bent that price 25×, and borrowed the entire pool — with $0 of my own money. Rebuilt in Foundry + proven on Sepolia 🧵

2/ The pool's oracle just asks a single DEX pool "what's the price right now?" That number is whatever the last swap made it. And a big enough swap can make it almost anything. Hold onto that.

3/ Flash-borrow $1M. Dump $800k into the pool in one swap. Spot price rockets from $2,000 to $49,880 — my collateral now looks ~25× more valuable than it really is. No capital committed; the flash loan fronts it all.

4/ Deposit the "valuable" collateral, borrow the whole pool — a full $1,000,000 — then repay the flash loan in the same tx. Walk away +$200,000. The pool is left holding collateral worth ~$160k against a $1M loan: ~$840k bad debt.

5/ The fix: never trust one pool's instant price. Read a Chainlink feed (aggregated across many nodes) or a TWAP (time-weighted average) instead. Now a single swap can't move the number the pool trusts — and the same attack reverts.

6/ All three steps ran as real txs on Sepolia — pump ($2k→$49.9k), deposit, borrow ($1M drain) — every field verifiable on Etherscan. Full code + line-by-line breakdown 👇
https://github.com/nikshev/unstuck/tree/main/episodes/defi-16-oracle-manipulation
