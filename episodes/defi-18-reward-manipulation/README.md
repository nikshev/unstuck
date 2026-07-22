# defi18 — Flash-Loan Reward Manipulation

A staking pool pays rewards **proportional to your stake at the instant you claim**.
A flash loan lets an attacker briefly *become* almost the entire pool, claim almost the
whole reward pot, then repay — all in one atomic transaction, with **zero** starting capital.
The reward token is a real, tradeable asset (think SUSHI / CAKE), so the ~100,000 tokens
drained are ~$100k the attacker can sell.

The fix: pay rewards by **liquidity × time-in-pool** (time-weighted). A position that exists
for 0 seconds earns 0 — so the same flash attack comes away with nothing.

## Reproduce it yourself

```bash
export RPC="https://your-sepolia-rpc-endpoint"
export PK="0xYOUR_FUNDED_SEPOLIA_PRIVATE_KEY"
./reproduce.sh          # forge tests + all 3 acts, live on Sepolia
```

Every `cast` command in the video is in `reproduce.sh`. Values are in wei (×10^18):
`100000000000000000000000` = 100,000 tokens.

## The exact transactions shown in the video (Sepolia)

**Act 1 — honest**  · pool `0xc734bF61e30f782298848AB199B15D3cDab1bd04` · RWD `0x4d7a67BA6bE4cEDCbaDb0c257b971fBDC29EC606`
- pot before: `cast call $POOL "rewardReserve()(uint256)"` → `100000000000000000000000` (100,000)
- Alice stake: [0xfb7cce…372a](https://sepolia.etherscan.io/tx/0xfb7cce556a8b96d720756e52842e3d31e3ed3e3aaeaf0c6dd07448677943372a)
- Bob stake:   [0xac5b99…7614](https://sepolia.etherscan.io/tx/0xac5b996000789fa04b83a71448f02731fb8c729e9c2a08f9d7b2a281bbd27614)
- Alice claim: [0x914cb2…c2f84](https://sepolia.etherscan.io/tx/0x914cb25231150f91f33361a5f03d29207818f6817574bd7fc1709636586c2f84) → Alice balance `50000e18` (fair 50%)

**Act 2 — attack**  · pool `0x62C7B6D224F5Ca389E372c51798AF4E047bE1096` · RWD `0x8523320dE62d2384CE1d6B58bd1577201a358E85` · attacker `0x80F3B4A57c27ce681f0939543b0B7c95808BC1ad`
- before: pot `100000e18`, attacker `0`
- attack: [0xbb7b76…ac07f](https://sepolia.etherscan.io/tx/0xbb7b7688f4ef22623c4d04ce2ce03bd82237a7e16187856b9350d30d786ac07f)
- after: pot `9999000099990001000` (~10 left), attacker `99990000999900009999000` (~99,990 stolen)

**Act 3 — fixed (time-weighted)**  · pool `0x717f1651562dcEdEaEe9a8e5A0775AE7a0373b3e` · RWD `0x4ada49b42a5f060985197f627f3f75b97b438fec` · attacker `0x3dE6C3a8E2Bb67F70F28987997e8B583728FD475`
- attack: [0xda4f03…220010](https://sepolia.etherscan.io/tx/0xda4f03d90ff9e226e3f90d4b43ca0888e09e0254eba08abe84b3301410220010)
- after: attacker `0` (0 seconds staked = 0 reward), pot `100000e18` untouched

## Files
- `src/StakingPool.sol` — the vulnerable, instantaneous-share pool
- `src/StakingPoolFixed.sol` — the time-weighted fix
- `src/FlashLender.sol`, `src/Attacker.sol` — the one-tx exploit
- `test/RewardManip.t.sol` — the three acts as Foundry tests (balance-by-balance logs)
- `script/*Sepolia.s.sol` — the on-chain deploys used above
