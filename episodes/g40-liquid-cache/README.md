# g40 — $320M: The Cache That Said Yes Before It Checked

Liquid Network, **6 September 2026**. No key was stolen, no cryptography was broken, and the federation
was never hacked. A **cache** answered a question it had never been asked.

## The bug

Elements' `CachingRangeProofChecker::VerifyRangeProof` cached range-proof results — sensible, since
verifying one is expensive. But the lookup ran **before** commitment parsing and
`secp256k1_rangeproof_verify`:

```
if (cache.contains(key)) return true;      <- answers HERE
parse_commitments(...);                    <- never reached
secp256k1_rangeproof_verify(...);          <- never reached
```

A cache **hit** did not confirm the cryptography. It **skipped** it.

And the key was built by concatenating four **variable-length** components — range proof, value
commitment, asset generator, output script — **with no delimiters**. Nothing recorded where one field
ended and the next began.

## The collision

```bash
python3 cache_collision.py
```

```
TX A - legitimate (this proof really verifies)
   proof  4234 B   +   script  67 B
   sha256 b7f71a25d87532134e6295cddc216c82...

TX B - the attack (invalid proof, empty script)
   proof  4301 B   +   script   0 B
   sha256 b7f71a25d87532134e6295cddc216c82...

identical?   True        both 4,301 bytes
```

The attacker moved **67 bytes** from the script onto the end of the proof. Same stream, different
transaction. Nothing was forged.

> ⚠️ This models the ambiguity between two **adjacent** variable-length fields — which *is* the
> mechanism. It is not Elements source, and the exact field ordering there is not published in detail.
> (The first version of this script shifted *non-adjacent* fields and printed `identical? False`.
> Collisions only arise across a shared boundary.)

## Thirty-six minutes (6 Sep, UTC)

| time | |
|---|---|
| 13:52:10 | setup transaction primes the cache — a legitimate proof, verified honestly |
| 13:53:10 | **~4,000 unbacked L-BTC minted** — same key, cache hit, 60 seconds later |
| 14:06:10 | peg-out request for 3,996.02 L-BTC |
| 14:28 | **federation releases 3,996.02 real BTC** — operating exactly as designed |

Next day: ~3,400 BTC returned with OP_RETURN messages declaring "we are whitehats"; **598.5 BTC
(~$47M) kept** as a self-declared bounty. Blockstream called taking assets without authorization
"a crime, not responsible disclosure".

## The fix — four bytes per field

```python
sha256( len(proof)  || proof
     || len(script) || script )
```

Write down where each field ends instead of guessing. Shipped as Elements **v23.3.4**.

**It was merged to master on 1 September. The attack was on 6 September.** Five days — but no tagged
release carrying it had reached a production node. For those five days the fix and the vulnerability
were both public in the same repository.

**A security fix that exists but has not shipped is not a fix. It is a public description of your
vulnerability.**

## The pattern (fourth time on this channel)

| episode | the thing that looked like a check |
|---|---|
| [`../g34-coldcard`](../g34-coldcard) | tested whether a macro **existed**, not whether it was **on** |
| [`../g37-cosmos-underflow`](../g37-cosmos-underflow) | checked arithmetic one layer **above** the bug |
| g35 *They Passed the Audit* | a finding rated on an assumption nobody examined |
| **g40 (this)** | a cache key that **answered before anything was verified** |

In all four, no component was broken. Each was answering a slightly different question from the one
everyone assumed.

## Sources
rekt.news/liquid-network-rekt · CertiK forensic reconstruction (7 Sep) · Liquid Network incident
report · crypto.news · CryptoSlate · TechTimes
