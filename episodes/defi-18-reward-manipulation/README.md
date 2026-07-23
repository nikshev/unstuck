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

## Follow the tokens on Etherscan

The lab ERC-20 (`src/MockERC20.sol`) emits the standard **`Transfer`** event, so every
transaction below shows its full **ERC-20 Tokens Transferred** list on Etherscan — you can
see exactly which tokens moved, from whom, to whom, and how much. The attack is the clearest:
one transaction, five transfers, and the third one is the theft.

The attack tx — [`0xbc67c9…41df1f`](https://sepolia.etherscan.io/tx/0xbc67c951197900c1f82a1e197a58179053773102994ae7dd1cd1bd634e41df1f) — reads, in order:

| # | From | To | Amount | Token | What it is |
|---|------|----|--------|-------|-----------|
| 1 | Flash Lender | Attacker | 10,000,000 | LP  | flash loan out (no collateral) |
| 2 | Attacker | Pool | 10,000,000 | LP  | stake it all (~99.99% of the pool) |
| 3 | **Pool** | **Attacker** | **99,990** | **RWD** | **THE THEFT — almost the whole pot** |
| 4 | Pool | Attacker | 10,000,000 | LP  | unstake |
| 5 | Attacker | Flash Lender | 10,000,000 | LP  | repay the loan (same tx) |

On the fixed pool the same five transfers appear, but transfer #3 is **`0` RWD**.

## The exact transactions shown in the video (Sepolia)

**Act 1 — honest**  · pool `0xE8bd3b86cde5E8745b9fa08a996c315139B1af65` · RWD `0x73ce1879813c61F7582182D9D36A7e399A8f2495`
- pot before: `cast call $POOL "rewardReserve()(uint256)"` → `100000000000000000000000` (100,000)
- Alice stake: [0x0278f5…dccbb](https://sepolia.etherscan.io/tx/0x0278f52fe801db816230323311d1e514d0be2b11e2ec32d5bb1b8665854dccbb) — 1,000 LP → pool
- Bob stake:   [0xfabe35…f8e50](https://sepolia.etherscan.io/tx/0xfabe35671282590d8ad1316b91e73abd4e3390349e0b692be00c0b1cfd4f8e50) — 1,000 LP → pool
- Alice claim: [0x038949…09ddc4](https://sepolia.etherscan.io/tx/0x0389490109052affe514a151149e13e7263e1ea68e2975a98ab487e5e909ddc4) → pool sends Alice `50000e18` (fair 50%)

**Act 2 — attack**  · pool `0x3233F806de6105582fDfEB8E8DB82a9873EF17Df` · RWD `0x6e2812cA752b692be335fE9b90623b19fa160A22` · attacker `0x99577F6ADD247B58C795476ba7BB23D7fB4d99b7`
- before: pot `100000e18`, attacker `0`
- attack: [0xbc67c9…41df1f](https://sepolia.etherscan.io/tx/0xbc67c951197900c1f82a1e197a58179053773102994ae7dd1cd1bd634e41df1f)
- after: pot `9999000099990001000` (~10 left), attacker `99990000999900009999000` (~99,990 stolen)

**Act 3 — fixed (time-weighted)**  · pool `0xff52eCEFF369ce4702BB17Ec59b4b4eF3Af1d017` · RWD `0x63DEc45F4E0FA0e0AA6b9923D8d62D9498E9aB6C` · attacker `0x52bCC670ec85f075B0c25f4C705c4Af52f574081`
- attack: [0xeddd12…fed73ab](https://sepolia.etherscan.io/tx/0xeddd12224242e61fd9ec0c6711e687faf157f9901a8d5f67733440c47fed73ab)
- after: attacker `0` (0 seconds staked = 0 reward), pot `100000e18` untouched

## Files
- `src/StakingPool.sol` — the vulnerable, instantaneous-share pool
- `src/StakingPoolFixed.sol` — the time-weighted fix
- `src/FlashLender.sol`, `src/Attacker.sol` — the one-tx exploit
- `src/MockERC20.sol` — the lab token; emits `Transfer`/`Approval` so the flow shows on Etherscan
- `test/RewardManip.t.sol` — the three acts as Foundry tests (balance-by-balance logs)
- `script/*Sepolia.s.sol` — the on-chain deploys used above
