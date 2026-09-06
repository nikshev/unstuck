# g37 — They Reported This Bug in April. Six Chains Were Drained in August.

Companion code for the video.

## The defect

An **integer underflow in the Cosmos EVM staking precompile's post-delegation balance write-back.**
Reported through the Cosmos bug bounty on **25 April 2026**, closed because it could not be reproduced
on 18-decimal networks. Confirmed to affect *all* Cosmos EVM chains on **13 August**. Exploited across
**six chains, 20–25 August**.

> "We were unable to reproduce the vulnerability on 18-decimal networks and incorrectly concluded that
> it affected only non-18-decimal networks." — Cosmos Labs

## Why Solidity's protection didn't help

SafeMath, then Solidity 0.8 defaults, made underflow revert. That is real, and it works — **for
Solidity**. The precompile is **Go code beneath the EVM**. Checked arithmetic in one layer cannot
protect the layer under it. The industry hardened the floor; the bug was in the basement.

```
VULNERABLE                          HARDENED
new = u256(balance - amount)        if amount > balance:
store(addr, new)                        revert("insufficient")
                                    store(addr, balance - amount)
```

That is the entire fix. One comparison.

## Run it

```bash
python3 underflow_ledger.py
```

Models the *shape* of the defect — not Cosmos source, just the minimum code needed to show what the
machine actually believes afterwards. Full output: [`run.log`](run.log).

### 1. The subtraction

```
  balance      2,000,000,000,000,000,000
- amount       2,000,000,000,000,000,001
= true                                -1     <- negative. There is no negative.
= STORED   115,792,089,237,316,195,423,570,985,008,687,907,853,269,984,665,640,564,039,457,584,007,913,129,639,935
```

No exception. No error. No log line. A number was written to a field.

### 2. "So it subtracted. So what?"

Because that number **is** the ledger. Every downstream check reads it and answers honestly:

```
require(balance >= 1 KII)            -> PASS
require(balance >= 1,000,000 KII)    -> PASS
require(balance >= 10^30 KII)        -> PASS
```

**Nothing was bypassed.** The check is not broken — it ran, did its job, and returned the correct
answer about a number that is a lie. *You do not need to defeat the guard if you can edit what it reads.*

### 3. Why it HAS to be a vesting account

This is the piece that makes the rest possible:

| | knows |
|---|---|
| **EVM StateDB** | ONE number — `spendable` |
| **SDK vesting account** | TWO numbers — `spendable` + `locked` |

`x/staking` and the staking precompile both let you delegate the **locked** portion too. So the amount
you may delegate can be **larger than the number the EVM tracks**. That gap is the entire vulnerability
— and it is why the attacker pre-computed a contract address and converted it to a vesting account
*before* deploying. On an ordinary account those two numbers are equal and step 1 simply fails.

### 4. 900,000 → 0 and 2 → 900,000, derived

He sends **exactly `S = 2^256 − V`**. Not a round number — a chosen one.

```
VICTIM SIDE      V + S
    V     900,000,000,000,000,000,000,000
  + S     115,792,089,237,316,…,563,139,457,584,007,913,129,639,936
  =       115,792,089,237,316,…,564,039,457,584,007,913,129,639,936   <- exactly 2^256
  STORED  0

ATTACKER SIDE    A − S
    A     115,792,089,237,316,…,564,039,457,584,007,913,129,639,935
  − S     115,792,089,237,316,…,563,139,457,584,007,913,129,639,936
  STORED  899,999,999,999,999,999,999,999                            = 900,000 KII
```

The identities:

```
(2^256 − 1) − (2^256 − V)  =  V − 1     he ends up with the VICTIM'S balance
     V      + (2^256 − V)  =  2^256 = 0  she ends up with nothing
```

### 5. What "they cancel out" means

```
HIS dial rolled BACKWARD past 0    -> the machine INVENTED  + 2^256
HER dial rolled FORWARD past top   -> the machine DESTROYED − 2^256
                                      ---------------------------------
                                                                     0
```

Same invented amount: created once, destroyed once, in the same transaction. That is why the books
still add up, no alarm fires, and supply is genuinely unchanged. Strip the two phantoms away and what
is left underneath is **an ordinary transfer of V from her to him** — the phantoms were only the
mechanism that made the ledger willing to authorise it.

### 6. And *this* is the payday

Those tokens still sit on a chain run by the people he just robbed.

| # | step | amount |
|---|---|---|
| 1 | helper address → attacker's primary KiiChain address | a second EVM tx |
| 2 | **bridge OUT via Hyperlane → BNB Smart Chain** | 67,597,997.87 KII (45.6%) |
| 3 | **sell on PancakeSwap** | 64,597,997.87 KII into the pool |
| 4 | deposit to a CEX | 3,000,000 KII → KuCoin |
| 5 | **REALISED** | **≈ $1,600,000** |

Repeated **18×** against different targets → **148,326,583.15 KII**.

### The proof that selling is the real bottleneck

KiiChain halted at **block 9355723** (22:50:58 UTC). **80,728,575.06 KII — 54.4% — never left the
chain** and is still frozen in the attacker's own addresses. Same exploit, same balances; the half he
had not **sold** was worth nothing. KiiChain's fix landed exactly there: a **10M KII / 24h** egress cap
on the Hyperlane warp routes.

## Sources

rekt.news/kiichain-rekt (mechanism + KiiChain figures) · The Block · The Defiant · crypto.news ·
The Hacker News · coinpaprika

⚠️ KiiChain's post-mortem states that of the **three** defects this needed, only the underflow is
patched publicly upstream. That is their assessment — read it directly.

## Related

- [`../g34-coldcard`](../g34-coldcard) — a guard that tested existence instead of value
- [`../g36-40bits`](../g36-40bits) — measuring what a collapsed search space actually costs
