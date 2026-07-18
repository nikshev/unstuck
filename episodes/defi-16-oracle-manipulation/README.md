# DeFi Exploits — Ep 16: Flash-Loan Price-Oracle Manipulation

## 🎬 Watch

🔴 **New episode** — [Subscribe](https://www.youtube.com/channel/UC32d5uV5MEC1oMqVaVbQPNA?sub_confirmation=1) to catch it when it drops.

A lending app that prices your collateral off a **single DEX pool's live spot price** is trusting a number
anyone can move. The attacker **flash-borrows $1M**, dumps **$800k** into the pool in one swap so the spot
price rockets from **$2,000 to $49,880**, deposits the now-"valuable" collateral, **borrows the entire pool
($1,000,000)**, and repays the flash loan in the same transaction — **without a cent of their own money**.
Profit: **+$200,000**. The pool is left holding collateral truly worth **~$160k** against a $1M loan —
**~$840k of bad debt**.

## The idea in one test

`test/OracleManip.t.sol` wires up a `DexPool`, a `SpotOracle` (live price), a `LendingPool`, a `FlashLender`,
and an `Attacker`, then runs the attack on it:

- **`test_oracle_manip`** — flash-borrow $1M → swap $800k into the pool (**spot $2,000 → $49,880**) →
  deposit ~79.95 WETH → borrow **$1,000,000** → repay the flash loan → **+$200,000 from $0 capital**.
  The pool lent $1M against collateral worth ~$160k → **~$840k bad debt**.
- **`test_fixed`** — swap the `SpotOracle` for a Chainlink/TWAP-style `FixedOracle`. The manipulated spot
  price no longer counts, the attacker can't over-borrow to repay the flash loan, and the whole tx
  **reverts**.

> One pool's instant price is cheap to bend. Read a **Chainlink** feed (aggregated across many nodes) or a
> **TWAP** (time-weighted average) instead, and a single swap can't move the number the pool trusts.

## Run it yourself

Requires [Foundry](https://getfoundry.sh).

```bash
forge install foundry-rs/forge-std   # first time only
forge test -vv
```

You'll see `[PASS] test_oracle_manip` (spot **$2,000 → $49,880**, attacker **+$200,000** from $0 capital,
pool **~$840k** bad debt) and `[PASS] test_fixed` (with a Chainlink/TWAP oracle the attack **reverts**).

## Proven on Sepolia (public Etherscan)

`script/OracleManipSepolia.s.sol` deploys the DEX pool + vulnerable lending market and runs the attack as
**three real transactions** on the Sepolia testnet, through a Chainstack node:

1. **Pump** — [`0xe8f0…f191`](https://sepolia.etherscan.io/tx/0xe8f03800482fe6d419a849689fd37684fcaa6281d6f979d38b8f3197ee90f191) — swap 800k USD into the pool; the spot price jumps **$2,000 → $49,880**.
2. **Deposit** — [`0xf20a…f6aa44`](https://sepolia.etherscan.io/tx/0xf20aafc6ab9a0fd953fbdf6c339b45246157f64a4f701fcf7c6141e490f6aa44) — post the now-"valuable" collateral.
3. **Borrow** — [`0x9e38…9e1c407`](https://sepolia.etherscan.io/tx/0x9e383b2b2a172d30b67bb2326f2085f1c5de44246bab5b458fa423eab9e1c407) — borrow **$1,000,000**, draining the pool.

Pool `0xe478…5ca7` · lending `0x0d6b…f9d5` · three consecutive blocks.

## ⚠️ Educational only

Everything runs on a local chain / testnet — no real users or funds. Don't use any of this to harm others.
