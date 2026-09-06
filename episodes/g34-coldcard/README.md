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
