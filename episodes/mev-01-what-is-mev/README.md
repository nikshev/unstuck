# MEV Explained — Ep 1: What Is MEV?

## 🎬 Watch

🔜 **Video coming soon.** [Subscribe on YouTube](https://www.youtube.com/channel/UC32d5uV5MEC1oMqVaVbQPNA) to catch it.

**MEV = Maximal Extractable Value** — the profit you can extract purely by choosing the *order* of
transactions in a block. This episode explains MEV from the 2019 *Flash Boys 2.0* paper and proves,
with a real Foundry test you can run yourself, why getting in first is worth money — then shows the
original form of MEV, a **Priority Gas Auction**, on a local chain viewed in a block explorer.

## The idea in one test

`Opportunity` is a one-shot prize: the **first** caller to `take()` wins everything; everyone after
reverts. It stands in for any MEV opportunity (an arbitrage, a liquidation) — only one transaction
can capture the value, and only if it lands first.

`PriorityGasAuction.t.sol` proves the consequence: the searcher who is **ordered first** wins, and
the one behind them gets nothing. In a real block that order is decided by gas — so bots bid gas to
go first. That bidding war is a Priority Gas Auction.

## Run the test yourself
Requires [Foundry](https://getfoundry.sh).

```bash
forge install foundry-rs/forge-std   # first time only
forge test -vvv
```

You'll see both tests pass, with logs showing Searcher B (the higher bid) capturing the full 1 ETH
and Searcher A arriving too late.

## See the gas auction on a real chain
Requires Foundry + Docker. This spins up a local fork + the Otterscan explorer, sends two competing
transactions (5 gwei vs 120 gwei), and lets you watch the higher bid land in **position 0**.

```bash
export ETH_RPC_URL=<your mainnet RPC>     # Alchemy / Infura / your node
./mev-anvil.sh up                          # forked Anvil :8555 + Otterscan :5100
FORK_BLOCK=$(cast block-number --rpc-url http://127.0.0.1:8555) ./pga_demo.sh
```

Open **http://localhost:5100**, find the 120-gwei transaction, and check its **Block Position: 0**.
Stop everything with `./mev-anvil.sh down`.

## The bigger picture
- The gas auction is just the beginning. Ahead in this series: **arbitrage, sandwiches,
  liquidations, backruns/JIT** — each reproduced from scratch on a local fork.
- Today MEV flows through a supply chain: **searcher → builder → relay → proposer** (MEV-Boost).

## Sources
- Flash Boys 2.0 (Daian et al., 2019): https://arxiv.org/abs/1904.05234
- Flashbots docs: https://docs.flashbots.net/
- Foundry: https://getfoundry.sh · Otterscan: https://github.com/otterscan/otterscan
