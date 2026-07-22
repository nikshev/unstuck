# MEV — Ep 09: JIT Liquidity (Uniswap v3)

## 🎬 Watch

🔴 **New episode** — [Subscribe](https://www.youtube.com/channel/UC32d5uV5MEC1oMqVaVbQPNA?sub_confirmation=1) to catch it when it drops.

In a concentrated-liquidity pool (Uniswap v3), a swap's fee is split among LPs **in proportion to the
liquidity each holds at the instant of the swap** — with no regard for how long they've provided it.
**Just-in-time (JIT) liquidity** weaponizes that: a searcher watches the mempool for a big swap, mints a
mountain of liquidity in the block **right before** it, collects nearly the **whole fee**, and burns the
position — capital at risk for a **single block**. It's not a bug to patch; it's an emergent consequence of
open mempools + concentrated liquidity, and the cost is quietly borne by the **passive LPs**.

## The idea in one test

`test/JitLiquidity.t.sol` builds a minimal pool (`MiniPool`) with a faithful `feeGrowthGlobal` fee
accumulator — the one property that matters. A passive LP holds **100** units; the JIT searcher adds
**9,900**; a **50-unit** swap pays a **0.3%** (**0.15**) fee.

- **`test_passive_baseline`** — with no JIT, the passive LP collects the **whole 0.15** fee.
- **`test_jit_steals_fee`** — all in one block, the searcher adds **9,900** (≈99% of the pool), the swap pays
  its fee, the searcher `collect`s **0.1485** (**>98%**) and `removeLiquidity`s — getting ~all its capital
  back (exposed **~1 block**). The passive LP is left with **0.0015** (**<2%**).

> There's no line to patch. The real defenses are **private orderflow** (so the searcher never sees the swap
> coming) and pool designs that reward liquidity for **time in range**, so a one-block position can't scoop a
> standing LP's fees.

## Run it yourself

Requires [Foundry](https://getfoundry.sh).

```bash
forge install foundry-rs/forge-std   # first time only
forge test -vv
```

You'll see `[PASS] test_passive_baseline` (passive LP earns the full **0.15**) and `[PASS]
test_jit_steals_fee` (searcher scoops **0.1485 / 99%** for one block).

## Proven on Sepolia (public Etherscan)

`script/MiniPoolSepolia.s.sol` deploys the same pool through a Chainstack node. JIT is all about **ordering
within a block**, so the sequence runs as **five ordered, public transactions** you can open and read:

1. **JIT add** — [`0x3a11…7025b4`](https://sepolia.etherscan.io/tx/0x3a11a9afdde43880947ca25ce9d17fade6d278d0d352b9d8cbe36a41717025b4) — the searcher mints its huge position.
2. **Swap** — [`0xa37a…021b8f`](https://sepolia.etherscan.io/tx/0xa37a92e1a0ce666b12870e7abfd5f99f822d2052486fe7c20566223b4f021b8f) — the big swap pays its fee into the pool.
3. **JIT collect** — [`0x5ccd…062112`](https://sepolia.etherscan.io/tx/0x5ccd3aa2513f7bbfa27ca491ee19961d50a85ea52f31543006bb33469c062112) — the searcher takes ~all the fee.
4. **JIT remove** — [`0x839b…7b4dd9`](https://sepolia.etherscan.io/tx/0x839b07251bb18d5aa8bd1fdcde94892cb9252c338c77d41334f5ef20337b4dd9) — capital back out, same block.
5. **Passive collect** — [`0xf572…3dbde7`](https://sepolia.etherscan.io/tx/0xf5729ea5196f38121aa32e929b222ecd3fb25b3cd75226c3a1ecfb91f73dbde7) — the passive LP receives only a sliver.

Split: JIT **0.1485 (99%)** vs passive **0.0015 (1%)**. Pool `0x2B3A906ddbc1CC3a96D9B632E519453C5a4C9957` ·
JIT `0x2D04C5b3ADb0Ddd61a0114689E986DeEe0bDaba5` · passive `0xC628D33448e9722622B200d017C358466060e6d4`.

## ⚠️ Educational only

Everything runs on a local chain / testnet — no real users or funds. Don't use any of this to harm others.
