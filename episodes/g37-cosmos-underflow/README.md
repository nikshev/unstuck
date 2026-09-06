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

### 3. "So he resends it. So what?"

A 78-digit balance in your own row is not money. To become money it has to **move** — and a transfer is
the only operation that touches two rows. The receiving side wraps too, in the other direction:

```
  victim balance   900,000,000,000,000,000,000,000
+ incoming         115,792,089,237,316,195,423,…,639,936
= true sum         over the 2^256 ceiling
= STORED           0
```

900,000 KII gone from the ledger. **Nothing minted, nothing burned** — total supply unchanged, which is
exactly what Cosmos Labs reported. A wrap moves value between rows instead of creating it.

## Sources

rekt.news/kiichain-rekt (mechanism + KiiChain figures) · The Block · The Defiant · crypto.news ·
The Hacker News · coinpaprika

⚠️ KiiChain's post-mortem states that of the **three** defects this needed, only the underflow is
patched publicly upstream. That is their assessment — read it directly.

## Related

- [`../g34-coldcard`](../g34-coldcard) — a guard that tested existence instead of value
- [`../g36-40bits`](../g36-40bits) — measuring what a collapsed search space actually costs
