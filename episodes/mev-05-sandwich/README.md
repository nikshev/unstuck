# MEV Explained — Ep 5: The Sandwich Attack

## 🎬 Watch

📅 **Premieres Jul 20, 2026.** [Subscribe on YouTube](https://www.youtube.com/channel/UC32d5uV5MEC1oMqVaVbQPNA) to catch it.

The most common attack in MEV, built on the **real** Uniswap v2 WETH/USDC pool. A searcher sees a
whale's big swap sitting in the public mempool, **front-runs** it (buying first, pushing the price up),
lets the whale buy at the worse price, then **back-runs** (selling into the pool the whale just
inflated). The whale's slippage becomes the searcher's profit.

## The idea in one test
`test/Sandwich.t.sol` forks Ethereum mainnet at block `20,000,000` (the real Uni-v2 WETH/USDC pool,
~$54M deep) and runs the sandwich through the **real** Uniswap router:
- `test_sandwich` — records the whale's **fair** fill (via `vm.snapshotState` / `vm.revertToState`),
  then: **1)** searcher front-runs with $1,000,000, **2)** whale swaps $2,000,000 and gets **less than
  fair**, **3)** searcher back-runs. Result: whale short **17.79 WETH (~$68K)**, searcher **+$66,889 USDC**
  (~98% of the shortfall).
- `test_defended` — the whale sets a **0.5% slippage guard** (`amountOutMin`). Under the front-run the
  pool can't deliver it, so the swap **reverts** (`INSUFFICIENT_OUTPUT_AMOUNT`) — the sandwich can't land.

> The searcher's two trades bracket the victim's. The price swings up, then back. The gap you lose to
> slippage is the gap they take.

## Run it yourself
Requires [Foundry](https://getfoundry.sh) and a mainnet RPC (archive, for the fixed fork block).

```bash
forge install foundry-rs/forge-std     # first time only
export ETH_RPC_URL=<your mainnet RPC>
forge test -vv
```

You'll see `[PASS] test_sandwich` with the full ledger (`fair 503.47 → victim 485.68 → +66,889 USDC`)
and `[PASS] test_defended` (the guarded swap reverts under the front-run).

## Proven on Sepolia (public Etherscan)
`script/SandwichSepolia.s.sol` deploys a minimal deep pool (`MiniPair` + two `Mock20` tokens) and runs
the sandwich as **three real transactions** — front-run, victim, back-run — on the Sepolia testnet:

| # | Tx | Result |
|---|----|--------|
| 1 · FRONT-RUN (searcher) | [`0x44e2…a29b`](https://sepolia.etherscan.io/tx/0x44e2b1cb93e0f7416f402f9440a61a3a5e5f523b30586e7dc583f7285ebba29b) | $1,000,000 USDC → WETH, price pushed up |
| 2 · VICTIM (whale) | [`0xa942…e822`](https://sepolia.etherscan.io/tx/0xa942a1d87a8ad531afe369e4756a9e2d8ca85286249e29525a7c5a687c49e822) | $2,000,000 USDC → **463.75 WETH** (short of the fair 480.75) |
| 3 · BACK-RUN (searcher) | [`0x921d…c17fd`](https://sepolia.etherscan.io/tx/0x921d74cd2b830631512959bf715d3f36b0778d5b85518905d29d7083bc6c17fd) | WETH sold back → **+66,919 USDC profit** |

```bash
export PK=<your sepolia key>
forge script script/SandwichSepolia.s.sol:SandwichSepolia --rpc-url $SEPOLIA_RPC --broadcast --slow --legacy
```

## Key idea
- A sandwich = **front-run + your swap + back-run**, in one block; the searcher's profit *is* your slippage.
- **Defense 1 (free, always use it):** set a real `amountOutMin` so a manipulated price makes your swap revert, not fill.
- **Defense 2 (stronger):** keep your trade out of the public mempool — private orderflow (Flashbots Protect / MEV Blocker) so no one can front-run what they can't see.

## Sources
- Flash Boys 2.0 (Daian et al., 2019): https://arxiv.org/abs/1904.05234
- Uniswap v2 constant-product & pricing: https://docs.uniswap.org/contracts/v2/concepts/protocol-overview/how-uniswap-works
- Ethereum.org on MEV & sandwiching: https://ethereum.org/en/developers/docs/mev/
- Flashbots Protect: https://docs.flashbots.net/flashbots-protect/overview
- Foundry: https://getfoundry.sh
