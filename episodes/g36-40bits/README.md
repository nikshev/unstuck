# g36 — 40 Bits: I Built a Weak Wallet and Found It Again

Companion code for the video. Everything shown on screen is produced by this script.

## What this is

A **measurement**. It builds a real BIP39 wallet whose entropy is restricted to a tiny space
(default 2^16), finds it again by exhaustive search, and reports the real throughput. From that
measured rate it extrapolates to **40 bits** (the Coldcard Mk2/Mk3 case) and **128 bits** (the design
target).

## What this is NOT

- It does **not** reconstruct any device's RNG state.
- It **cannot** recover anyone's funds and never touches a real wallet.
- The only wallet it can find is the one it just generated, because we chose to make it weak.

That boundary is deliberate. The point is to show *why a search space size matters*, not to hand
anyone a tool.

## Run it

```bash
pip install mnemonic ecdsa
python3 seed_search.py --bits 16     # finds a wallet in ~1 minute
python3 seed_search.py --cost        # prefix-check vs seed-check cost
```

## Results on the machine used in the video

```
COST OF ONE CHECK
  cheap prefix compare (what the g31 GPU demo counted):    2,014,072 /s
  full BIP39 seed -> key -> address check:                       930 /s
  a real seed check is  ~2,166x  more expensive

16-bit search
  FOUND at index 65,529 after 65,530 tries in 68.6s
  measured rate: 955 full seed checks / second (single CPU core, pure Python)

Extrapolated from that measured rate
   entropy            search space          time
    16 bits                 65,536          1.1 minutes
    32 bits          4,294,967,296          52.3 days
    40 bits      1,099,511,627,776          36.7 years    <- Coldcard Mk2/Mk3
    48 bits    281,474,976,710,656          9,389 years
   128 bits             3.4 x 10^38         1.14 x 10^28 years  <- design target
```

Full run log: [`run_16bit.log`](run_16bit.log).

## Reading the 36.7 years correctly

That figure is a **floor**, not the cost of the attack. It assumes the slowest possible approach:

| | speed-up |
|---|---|
| pure Python → native libsecp256k1 | ~100× |
| one core → GPU / rented cluster | ~1,000×+ |
| blind sweep → targeted state reconstruction | the real multiplier |

The first two alone take 955/s to roughly 1M/s, which puts 2^40 at about **13 days**. And the real
attacker never swept 2^40 blindly — they enumerated plausible chip UIDs × timer values, a far smaller
structured set, then matched derived addresses against the public chain.

## The actual point

Two regimes, and the difference is of kind, not degree:

- **40 bits** — effort moves the answer. Better code, more machines, smarter ordering: years → hours.
- **128 bits** — effort changes nothing. 1,000× faster is still 10^25 years. This is why 128 was chosen.

A `#ifndef` that should have been `#if` did not make those wallets weaker. It moved them from one
category into the other.

## Related

- **Cold Card $130M** — the one line of C that caused it (episode g34)
- [`../g31-vanity`](../g31-vanity) — where the GPU number came from, and what it was actually counting
