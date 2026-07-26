# mev13 — Private Orderflow / MEV-Share (the sandwich defence)
A sandwich (front-run + your swap + back-run) only works if the searcher can **see** your swap in the
public mempool. Route it **privately** — straight to a block builder (Flashbots Protect / MEV Blocker /
MEV-Share) — and the searcher is blind, so there's nothing to sandwich. Bonus: MEV-Share can rebate you
part of the backrun value.
## Reproduce
```
./reproduce.sh
```
- `forge test -vv` — same 5-WETH victim buy: PUBLIC (wrapped by front/back-run) → **9,976 TOKEN**; PRIVATE (mined alone) → **14,244 TOKEN**.
- Live Anvil: deploy a pool, front-run then read the victim's output (9,976) vs a fresh pool with the victim alone (14,244) — ~30% saved by hiding from the mempool.
Files: `Pool.sol` (constant-product AMM), `Sandwich.t.sol` (public vs private test).
