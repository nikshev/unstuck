# DeFi Exploits — Ep 18: Flash-Loan Reward Manipulation

## 🎬 Watch

🔴 **New episode** — [Subscribe](https://www.youtube.com/channel/UC32d5uV5MEC1oMqVaVbQPNA?sub_confirmation=1) to catch it when it drops.

A staking pool holds a pot of **reward tokens** and pays each staker their **share of the pool at the
instant they claim** — `reward = pot * yourStake / totalStaked`. It never asks **how long** you staked.
That missing question, **duration**, is the whole bug. A **flash loan** lets anyone borrow millions with no
collateral for one transaction, so an attacker with **zero capital** borrows an enormous stake, becomes
~**99.99%** of the pool for a single instant, `claim()`s almost the entire pot, then unstakes and repays —
all in **one atomic transaction**. Here the honest staker's rewards walk straight out the door.

## The idea in one test

`test/RewardManip.t.sol` funds a **100,000 RWD** pot, seats an honest **1,000 LP** staker, and runs both
the attack and the fix:

- **`test_drain`** — the attacker flash-borrows **10,000,000 LP**, stakes it (≈99.99% of the pool), `claim`s
  **99,990 of 100,000 RWD**, unstakes, and repays the loan in one `attack()` call → **attacker +99,990 RWD
  from zero capital**, pot left with **~10**, and holds **no LP** (loan repaid).
- **`test_fixed`** — `StakingPoolFixed` accrues rewards **per second** (a `rewardPerToken` accumulator, the
  Synthetix design). The **same** flash-loan attack now earns **exactly 0**, because staking and claiming in
  one transaction spans **0 seconds**.

> The fix is to reward **time in the pool**, not a snapshot. A flash loan can make you enormous for an
> instant, but time-weighting means an instant is worth nothing — and a flash loan can't fake duration.

## Run it yourself

Requires [Foundry](https://getfoundry.sh).

```bash
forge install foundry-rs/forge-std   # first time only
forge test -vv
```

You'll see `[PASS] test_drain` (a zero-capital attacker scoops **99,990 RWD**) and `[PASS] test_fixed`
(the same attack on the time-weighted pool earns **0**).

## Proven on Sepolia (public Etherscan)

`script/RewardSepolia.s.sol` deploys the same vulnerable pool + flash lender + attacker through a Chainstack
node. The exploit is **atomic**, so it's shown as **before → the single attack() tx → after**, all `cast`-
readable:

- **Before** — pool `rewardReserve` = **100,000 RWD**, attacker RWD = **0**.
- **Attack** — [`0x188f…7036d5`](https://sepolia.etherscan.io/tx/0x188f9b80fbb5ce6709f96ec2c0c04c2390f717aeebc0f51f1f024e485e7036d5) — one tx does borrow → stake → claim → unstake → repay (open it to see the internal reward transfer).
- **After** — pool `rewardReserve` = **~10 RWD**, attacker RWD = **99,990** (matches the forge test).

Pool `0xC9774d3717fDB85bfc38934156C679f9b1a592A0` · attacker `0x90f07D9191b28f7cfb7066Dbd2f63B05d1c07309`.

## ⚠️ Educational only

Everything runs on a local chain / testnet — no real users or funds. Don't use any of this to harm others.
