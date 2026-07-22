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

## The exact transactions shown in the video (Sepolia)

**Act 1 — passive LP earns the whole fee**  · pool `0xa6c0cB47bF41d9A967e9cd4450aa77423Ce370f4`
- passive add: [0x08ba77…306c](https://sepolia.etherscan.io/tx/0x08ba7790ac4812708e04199ae0b795d5a5277d17e7f0cb62ec9c408cf908306c)
- trader swap: [0xbd1e95…ce0b](https://sepolia.etherscan.io/tx/0xbd1e959cc4454657d3048ed696ba5bfdcc242a499222ddc420fa906d129dce0b)
- passive `collected()` → `300000000000000000000` (300 = the whole fee)

**Act 2 — atomic JIT takes ~99%**  · pool `0x832ba5029A0FE86D08c5f4d5B53dF756329Ee9a8` · bundle `0xb9427089EcdD4c6dE55d5d66e05EfAc5d9A6a498`
- JIT bundle (mint+swap+collect+burn, one tx): [0x9d7e1d…88a1](https://sepolia.etherscan.io/tx/0x9d7e1d420f7104d3898de52f40fc34e963a5e2a3c34b532def0fcf4ec5da88a1)
- bundle `jitFee()` → `297000000000000000000` (297 = 99%)
- passive `collected()` → `3000000000000000000` (3 = the 1% left)

**Act 3 — time-weighted pool: same JIT earns 0**  · pool `0x0d0e1ab153F6C718Ae5B3E3231dAADdDFD8131af` · bundle `0x9ce17307359b697f99CA3f523d94Dd2284cADE2b`
- JIT bundle (same atomic move): [0x8d5be8…b73ef](https://sepolia.etherscan.io/tx/0x8d5be86fdbf078323c8dc097587d552ddd574a7ad8205bfc4a3c7768236b73ef)
- bundle `jitFee()` → `0` (0 seconds in pool = 0 liquidity-seconds)
- passive `collected()` → `300000000000000000000` (300 = passive keeps it all)

## Files
- `src/MiniPool.sol` — instantaneous-share pool (vulnerable to JIT)
- `src/MiniPoolTW.sol` — the time-weighted fix (fees by liquidity-seconds)
- `src/JitBundle.sol` — the one-tx JIT sandwich (mint→swap→collect→burn)
- `src/Actor.sol` — a stand-in LP/trader; `collected()` stores the last fee received
- `test/JitLiquidity.t.sol` — the three acts as Foundry tests (who-earns-what logs)
- `script/JitActsSepolia.s.sol` — the on-chain deploys used above
