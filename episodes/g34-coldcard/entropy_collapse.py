#!/usr/bin/env python3
"""Where do 128 bits go? — the Coldcard entropy collapse, demonstrated by counting.

This does NOT reimplement Yasmarang or attack any device. It models the SHAPE of the failure:
a generator whose OUTPUT is 128 bits wide, but whose STATE is small, so the number of distinct
outputs it can ever produce equals the size of that state, not 2**128.

Run:  python3 entropy_collapse.py
"""
import hashlib, struct

def prng_output(state: int) -> bytes:
    """A 128-bit-WIDE output derived deterministically from a small state.
    Any deterministic PRNG has this property; the algorithm doesn't matter."""
    return hashlib.sha256(struct.pack(">Q", state)).digest()[:16]


def count_distinct(state_bits: int) -> int:
    """How many DIFFERENT 128-bit outputs can this generator ever produce?"""
    return len({prng_output(s) for s in range(1 << state_bits)})


def main():
    print("=" * 66)
    print("1. THE OUTPUT IS ALWAYS 128 BITS WIDE — that is what you see")
    print("=" * 66)
    for s in (3, 10, 16):
        out = prng_output(s)
        print(f"   state={s:<6} -> {out.hex()}   ({len(out)*8} bits wide)")
    print("\n   Every one of these looks like a full-strength seed. None of them is.\n")

    print("=" * 66)
    print("2. NOW COUNT HOW MANY DIFFERENT OUTPUTS ARE REACHABLE")
    print("=" * 66)
    print(f"   {'state bits':>11} {'possible states':>18} {'distinct outputs':>18}  {'real entropy':>13}")
    for bits in (4, 8, 12, 16, 20):
        n = count_distinct(bits)
        print(f"   {bits:>11} {1 << bits:>18,} {n:>18,}  {bits:>10} bits")
    print("\n   Distinct outputs == the state space. The 128-bit width is decoration.\n")

    print("=" * 66)
    print("3. THE COLDCARD SEEDING — where the bits actually went")
    print("=" * 66)
    print("   Yasmarang was seeded ONCE from three things:")
    print("     - the low 32 bits of the chip UID   (fixed in silicon, NOT secret)")
    print("     - the SysTick counter               (time since power-on)")
    print("     - two RTC registers                 (wall-clock time)")
    print()
    print("   The UID is not secret, but an attacker still has to ENUMERATE it,")
    print("   so it costs work: 32 bits. The timers are not secret either — their")
    print("   cost is only however much uncertainty the attacker cannot bound.")
    print()
    print(f"   {'attacker can pin the setup window to...':<42}{'timer bits left':>16}{'TOTAL':>8}")
    for label, timer_bits in (("the exact minute", 4),
                              ("roughly the hour", 8),
                              ("roughly the day", 16),
                              ("nothing at all (full 64-bit timers)", 64)):
        print(f"   {label:<42}{timer_bits:>16}{32 + timer_bits:>8}")
    print()
    print("   Coinkite / Block Engineering put the real figure at ~40 bits for Mk2/Mk3.")
    print("   That is THEIR measurement, not a number this script derives — but notice")
    print("   it falls exactly where '32 bits of UID + ~8 bits of residual timer' lands.")
    print()
    print("   Designed:  128 bits")
    print("   Actual:    ~40 bits")
    print("   Lost:       88 bits  =  88 HALVINGS of the attacker's work\n")

    print("=" * 66)
    print("4. WHAT EACH BIT IS WORTH")
    print("=" * 66)
    print("   Every bit you remove HALVES the search. The scale is not intuitive:")
    print(f"   {'bits':>6} {'search space':>34}")
    for b in (40, 48, 64, 80, 96, 112, 128):
        print(f"   {b:>6} {1 << b:>34,}")
    print(f"\n   128 -> 40 does not divide the work by 3.")
    print(f"   It removes {128-40} doublings: 2^128 / 2^40 = 2^{128-40} times easier.\n")


if __name__ == "__main__":
    main()
