# mev12 — NFT Mint & Listing Sniping

A scarce first-come-first-served mint (or a mispriced listing) sits in the **public mempool**. The block
is ordered by **priority gas**, not by who submitted first — so a bot that pays a higher tip is placed
ahead of a human who clicked earlier, and takes the token. You don't outbid on price; you outbid on gas.

**Defenses:** private orderflow (Flashbots Protect) so the bot can't see your tx, or fair design
(commit-reveal, allowlist, batch/uniform-price auction) so raw gas doesn't decide the winner.

## Reproduce
```
./reproduce.sh
```
- `forge test -vv` — the tx ordered first mints token #0; the one ordered second reverts `"sold out"`.
  A control test proves it's purely ordering; a listing-snipe test shows the same on a mispriced sale.
- Live Anvil (`--order fees`): the user submits `mint()` first @1 gwei, the sniper after @5 gwei; both
  queue in the mempool; one mined block orders the **sniper at position 0** → `ownerOf(#0)` = sniper,
  the user's tx fails `"sold out"`.

Files: `RareMint.sol` (scarce FCFS mint), `Market.sol` (mispriced listing), `Snipe.t.sol` (the tests).
