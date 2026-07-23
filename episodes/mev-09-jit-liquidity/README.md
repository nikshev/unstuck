# mev09 — JIT (Just-In-Time) Liquidity

A Uniswap-v3-style pool splits each swap's 0.3% fee among LPs **by the liquidity they hold at the
instant of the swap**. A JIT searcher exploits that: in one atomic transaction it mints an enormous
position just before a big swap, collects ~99% of the fee, and burns — exposed for **zero seconds**.
The fee is real money (a token like USDC/WETH), so the passive LP that genuinely provided the pool is
left with a rounding error.

The demonstrable defense: pay fees by **liquidity × time-in-pool** (liquidity-seconds). A position that
lives for 0 seconds earns 0 — so the same atomic JIT comes away with nothing, and the passive LP keeps
the whole fee. (The primary real-world defense is **private orderflow**: hide the swap so the searcher
can't see it coming.)

## Reproduce it yourself

```bash
export RPC="https://your-sepolia-rpc-endpoint"
export PK="0xYOUR_FUNDED_SEPOLIA_PRIVATE_KEY"
./reproduce.sh          # forge tests + all 3 acts, live on Sepolia
```

Values are in wei (×10^18): `300000000000000000000` = 300 T1. Fee on a 100,000 swap = 0.3% = 300 T1.
`src/JitBundle.sol` does the whole JIT move (mint→swap→collect→burn) in **one atomic tx**; read
`jitFee()` for the exact fee it captured, and `Actor.collected()` for the passive LP's share.

## Follow the tokens on Etherscan

The lab ERC-20 (`src/MockERC20.sol`) emits the standard **`Transfer`** event, so every transaction
shows its full **ERC-20 Tokens Transferred** list on Etherscan. The JIT bundle is the clearest: one
atomic transaction, seven transfers, and the fifth is the hijack.

The JIT bundle tx — [`0x3fd16c…a40149`](https://sepolia.etherscan.io/tx/0x3fd16c62e76e152c561303b99936f2885a1d016a72de7871e307a565b9a40149) — reads, in order:

| # | From | To | Amount | Token | What it is |
|---|------|----|--------|-------|-----------|
| 1 | JIT Searcher | Pool | 9,900,000 | T0 | mint ~99% of the pool |
| 2 | JIT Searcher | Pool | 9,900,000 | T1 | mint (both tokens) |
| 3 | JIT Searcher | Pool | 100,000 | T1 | the big swap — input |
| 4 | Pool | JIT Searcher | ~98,716 | T0 | the big swap — output |
| 5 | **Pool** | **JIT Searcher** | **297** | **T1** | **THE FEE — 99% of the 0.3%** |
| 6 | Pool | JIT Searcher | ~9,802,271 | T0 | burn — pull liquidity back |
| 7 | Pool | JIT Searcher | ~9,998,703 | T1 | burn (both tokens) |

On the time-weighted pool the same seven transfers appear, but transfer #5 is **`0` T1**.

## The exact transactions shown in the video (Sepolia)

**Act 1 — passive LP earns the whole fee**  · pool `0xe963573b9341b8c216cbc1539eb892176532C424`
- passive add: [0x006c0a…d0e8c](https://sepolia.etherscan.io/tx/0x006c0a4f1d441d4e3d0732ba09804ca9f9496f565694008a8f1c6eba816d0e8c) — 100,000 T0 + 100,000 T1 → pool
- trader swap: [0x2308c8…b17e75](https://sepolia.etherscan.io/tx/0x2308c86618676cb01906d7d0849265866e77ba3c23e51e30313083860eb17e75) — 100,000 T1 in, ~49,925 T0 out
- passive collect: [0xddb0ee…6e72c71](https://sepolia.etherscan.io/tx/0xddb0eed2f5807ad8fb4cfe49d794c5e8f753f8635ef835f3943cbce556e72c71) → `collected()` = `300000000000000000000` (300 = the whole fee)

**Act 2 — atomic JIT takes ~99%**  · pool `0x004491FD5484DE4e7A1334652C5Fda61238Ae3Ff` · bundle `0xdD6f3A7caD71DE86ED6b30aFfd1111f5cF8aC126` · passive `0xeEd3D2411A1a483A2a1F186357112a5C459F63ee`
- JIT bundle (mint+swap+collect+burn, one tx): [0x3fd16c…a40149](https://sepolia.etherscan.io/tx/0x3fd16c62e76e152c561303b99936f2885a1d016a72de7871e307a565b9a40149)
- bundle `jitFee()` → `297000000000000000000` (297 = 99%)
- passive collect: [0xd0c91b…2c274c](https://sepolia.etherscan.io/tx/0xd0c91bb702580612dc1a4de7cf2a714586c9305df4b440de2ea4b0822b2c274c) → `collected()` = `3000000000000000000` (3 = the 1% left)

**Act 3 — time-weighted pool: same JIT earns 0**  · pool `0x79Ae8eF1Be11c325bf5F42E38758D97758B74a0a` · bundle `0xe54e79da9514E66769A921f946cAff3a1b62fD0a` · passive `0x7383299e594aC2D4e8dBF13B760C00D5836a60fd`
- JIT bundle (same atomic move): [0xe1e358…be3033](https://sepolia.etherscan.io/tx/0xe1e358d711c790ed23ccd95d98b3de992cefde8ece97ed78a060275242be3033)
- bundle `jitFee()` → `0` (0 seconds in pool = 0 liquidity-seconds)
- passive collect: [0x282c85…29eab7](https://sepolia.etherscan.io/tx/0x282c85664cb48d38488e12f94ade7691aeb41cb3d76167821a80bcae5229eab7) → `collected()` = `300000000000000000000` (300 = passive keeps it all)

## Files
- `src/MiniPool.sol` — instantaneous-share pool (vulnerable to JIT)
- `src/MiniPoolTW.sol` — the time-weighted fix (fees by liquidity-seconds)
- `src/JitBundle.sol` — the one-tx JIT sandwich (mint→swap→collect→burn)
- `src/Actor.sol` — a stand-in LP/trader; `collected()` stores the last fee received
- `src/MockERC20.sol` — the lab token; emits `Transfer`/`Approval` so the flow shows on Etherscan
- `test/JitLiquidity.t.sol` — the three acts as Foundry tests (who-earns-what logs)
- `script/JitActsSepolia.s.sol` — the on-chain deploys used above
