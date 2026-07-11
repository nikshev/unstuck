# MEV Explained — Ep 1: What Is MEV?

**MEV = Maximal Extractable Value** — the profit you can extract purely by choosing the *order*
of transactions in a block. This episode explains MEV from the 2019 *Flash Boys 2.0* paper and
reproduces the original form of it — a **Priority Gas Auction (PGA)** — live on a local fork of
Ethereum, then verifies it in a real block explorer (Otterscan).

## What you'll see
Two "searchers" want the same slot. Searcher A submits first and bids **5 gwei**; Searcher B
submits *second* and bids **120 gwei**. When the block is built, the 120-gwei transaction lands in
**position 0** — the top of the block. Being early doesn't matter; paying more does. That is a
Priority Gas Auction: the crudest, original form of MEV.

## Run it yourself
Requires [Foundry](https://getfoundry.sh) (`anvil`, `cast`) and Docker.

```bash
export ETH_RPC_URL=<your mainnet RPC>     # Alchemy / Infura / your node
./mev-anvil.sh up                          # forked Anvil on :8555 + Otterscan on :5100
FORK_BLOCK=$(cast block-number --rpc-url http://127.0.0.1:8555) ./pga_demo.sh
```

Then open **http://localhost:5100** (Otterscan) and look up the winning transaction — its
**Block Position is 0** and its **Gas Price is 120 Gwei**.

Stop everything with `./mev-anvil.sh down`.

## The bigger picture
- The gas auction is just the beginning. Ahead in this series: **arbitrage, sandwiches,
  liquidations, backruns/JIT** — each reproduced from scratch on a local fork.
- Today MEV flows through a supply chain: **searcher → builder → relay → proposer** (MEV-Boost).

## Sources
- Flash Boys 2.0 (Daian et al., 2019): https://arxiv.org/abs/1904.05234
- Flashbots docs: https://docs.flashbots.net/
- Otterscan: https://github.com/otterscan/otterscan
