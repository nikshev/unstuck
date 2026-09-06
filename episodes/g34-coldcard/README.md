# g34 — Cold Card $130M: The One Line of C

Companion code for the video.

## The bug (verbatim, from the Block Engineering write-up)

```c
extern uint32_t rng_get(void);
#define CHIP_TRNG_32() rng_get()
#ifndef MICROPY_HW_ENABLE_RNG
#error "get a HW TRNG plz"
#endif
```

A **safety check** meant to fail the build if no hardware TRNG was configured.
`#ifndef` tests **existence**, not **value**. Coldcard's board config set
`MICROPY_HW_ENABLE_RNG = 0` — deliberately, because Coldcard shipped its own hardware-RNG
wrapper. The macro existed, so `#error` never fired, the build stayed green, and
MicroPython's deterministic **Yasmarang** PRNG generated real seeds for five years.

## What this code shows

`entropy_collapse.py` / `entropy_collapse.ipynb` demonstrate — by counting, not by asserting —
why a generator can emit 128-bit-wide output while carrying far less entropy.

```bash
python3 entropy_collapse.py
```

Or open the notebook in Colab (GPU cell included):
https://colab.research.google.com/github/nikshev/unstuck/blob/main/episodes/g34-coldcard/entropy_collapse.ipynb

### The argument in one table

The output width never changes. The number of **reachable** outputs is the state space:

| state bits | possible states | distinct 128-bit outputs | real entropy |
|---:|---:|---:|---:|
| 4 | 16 | 16 | 4 bits |
| 8 | 256 | 256 | 8 bits |
| 12 | 4,096 | 4,096 | 12 bits |
| 16 | 65,536 | 65,536 | 16 bits |
| 20 | 1,048,576 | 1,048,576 | 20 bits |

The 128-bit width is decoration.

### Where the Coldcard bits went

Yasmarang was seeded **once** from the low 32 bits of the chip UID (fixed in silicon, not
secret), the SysTick counter, and two RTC registers. The UID is not secret, but an attacker
must still *enumerate* it — so it costs 32 bits of work. The timers cost only whatever
uncertainty the attacker cannot bound:

| attacker can pin the setup window to… | timer bits left | total |
|---|---:|---:|
| the exact minute | 4 | 36 |
| **roughly the hour** | **8** | **40** |
| roughly the day | 16 | 48 |
| nothing at all | 64 | 96 |

Coinkite / Block Engineering put the real figure at **~40 bits** for Mk2/Mk3. That is *their*
measurement, not something this code derives — but it lands exactly where "32 bits of UID +
~8 bits of residual timer" does.

**Designed: 128 bits. Actual: ~40. Lost: 88 — that is 88 halvings of the attacker's work.**

## One device, counted start to finish

`worked_example.py` walks a single (illustrative) device so the ~40 stops being an abstraction:

```
THE DEVICE
  chip UID (low 32 bits) : 0x7C3A19E4
  set up                 : 14 March 2023, between 19:00 and 20:00
  Nothing here is secret. The owner did nothing wrong at any point.

WHAT THE ATTACKER MUST GUESS
  1. Which chip made it?          4,294,967,296  possible UIDs   (2^32)
  2. Exactly when was it set up?            256  timer states    (2^8)

  4,294,967,296  x  256  =  1,099,511,627,776  =  2^40

AND THEN WE GET THIS PICTURE
  what he actually has to search :                    1,099,511,627,776
  what the DESIGN promised       : 340,282,366,920,938,463,463,374,607,431,768,211,456

  on a free Colab T4 (54,443,902,652 ops/sec):
     2^40  ->  20.2 seconds
     2^128 ->  1.98e+20 years
```

The UID and the setup window are made up. **The arithmetic is the real part** — it is how a
specific attacker's knowledge turns into a specific number of guesses.

### Measured on a free Colab T4 (notebook section 5)

```
Tesla T4, 15360 MiB
walked 67,108,864 candidates in 1.2 ms
rate: 54,443,902,652 candidates/second

2^40  at this rate: 20.2 seconds
2^128 at this rate: 1.98e+20 years
```

⚠️ That loop counts a **cheap** operation, like the vanity-address demo — not a full BIP39 seed
derivation, which is ~2,000x dearer (measured in [`../g36-40bits`](../g36-40bits)). Read the
**ratio**, not either absolute time: whatever you multiply both by, 20 seconds stays in the world of
things that happen and 10^20 years does not.

## Affected

Coldcard **Mk2 / Mk3**, firmware **4.0.0 – 4.1.9**. Introduced in a March 2021 libngu migration.
Patched firmware shipped 2 Aug 2026 — but **a seed generated on broken firmware stays weak
forever**. The only fix is a new seed on patched firmware, then moving every coin across.

## Sources

- Block Engineering — *Predictable RNG Fallback and 32-Bit Reseed in COLDCARD Firmware*
- rekt.news/coldcard-rekt · BlockSec · OneKey · Wizardsardine · TRM Labs
- MicroPython postmortem discussion #19588

## Related

- [`../g36-40bits`](../g36-40bits) — measuring what 40 bits actually costs to search
- [`../g31-vanity`](../g31-vanity) — how addresses are generated, and the GPU number
