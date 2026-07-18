# MEV Explained — Ep 6: Backrunning

## 🎬 Watch

📅 **Premieres Jul 22, 2026** — https://youtu.be/eWiVHXVKhuQ · [Subscribe](https://www.youtube.com/channel/UC32d5uV5MEC1oMqVaVbQPNA?sub_confirmation=1) to catch it.

The gentle cousin of the sandwich. A searcher does **nothing** to anyone — it waits for a big trade to
land, knocking one pool's price out of line with the rest, then trades **right after** it (back-running),
buying the now-cheap side and selling the now-expensive side. It's **risk-free** (the price already moved)
and **victimless** (it just corrects the price). This is most of what MEV actually is.

## The idea in one test

`test/BackRun.t.sol` forks Ethereum mainnet at block `20,000,000` — the **real** Uniswap v2 and SushiSwap
WETH/USDC pools — and runs:

- **`test_backrun`** — first it measures the arb available **before** the whale (≈ **−$42K**: two aligned
  pools, nothing to take but fees). Then a whale buys **~742 WETH** on Uniswap, de-pegging it. Immediately
  after, the searcher buys the now-cheap WETH on Sushi and sells it on the now-expensive Uniswap:
  **+$10,099 USDC**, risk-free, created entirely by the whale's trade.

> A `vm.snapshotState` / `vm.revertToState` helper peeks at the free money available *right now* without
> actually trading — so you can prove there was none before the whale, and plenty after.

## Run it yourself

Requires [Foundry](https://getfoundry.sh) and a mainnet RPC (archive, for the fixed fork block).

```bash
forge install foundry-rs/forge-std   # first time only
export ETH_RPC_URL=<your mainnet RPC>
forge test -vv
```

You'll see `[PASS] test_backrun` with the ledger (`arb BEFORE −$41,874 → whale 742 WETH → backrun +$10,099`).

## Proven on Sepolia (public Etherscan)

`script/BackrunSepolia.s.sol` deploys a minimal two-pool lab (two constant-product `Pool`s + `MockERC20`
WETH/USDC) and runs the sequence as **three real transactions** on Sepolia, through a Chainstack node —
landing in **three consecutive blocks**:

1. **Whale** — [`0x8ebd…4ad653`](https://sepolia.etherscan.io/tx/0x8ebd58bc0112f463bcb36bfc300bd4e8cff07bf577efc89a92fe5d44e94ad653) — dumps 3,000,000 USDC into the Uniswap pool, takes 987 WETH → its price spikes.
2. **Backrun buy** — [`0x5315…b0b609`](https://sepolia.etherscan.io/tx/0x53152df94f92a3bd741ce36400a75da7c9acb3ecdde9cb1407bf9512adb0b609) — searcher spends 500,000 USDC on the still-cheap Sushi pool → 165.9 WETH.
3. **Backrun sell** — [`0x1b76…bf90b5`](https://sepolia.etherscan.io/tx/0x1b76d85086d5276fb7330a7dff630e0a7b305caf209d63a26d902fbbdebf90b5) — sells those 165.9 WETH on the now-pricey Uniswap pool → 505,294 USDC.

Searcher put in **500,000** and pulled out **505,294** = **+5,294 USDC**, risk-free — it never touched the whale.

## ⚠️ Educational only

Everything runs on a mainnet fork / testnet — no real users or funds. Don't use any of this to harm others.
