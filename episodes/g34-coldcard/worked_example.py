#!/usr/bin/env python3
"""ONE device, one attacker, counted step by step.

Illustrative: the UID and the setup window below are made up. What is real is the
ARITHMETIC — how a specific attacker's knowledge turns into a specific number of guesses.
"""
UID_BITS   = 32          # low 32 bits of the STM32 unique ID, mixed into the seed
TIMER_BITS = 8           # residual uncertainty if the setup hour is known

EXAMPLE_UID   = 0x7C3A19E4
SETUP_WINDOW  = "14 March 2023, some time between 19:00 and 20:00"

print("=" * 70)
print("THE DEVICE")
print("=" * 70)
print(f"  chip UID (low 32 bits) : 0x{EXAMPLE_UID:08X}   ({EXAMPLE_UID:,} in decimal)")
print(f"  set up                 : {SETUP_WINDOW}")
print(f"  seed it produced       : a normal-looking 12-word mnemonic")
print()
print("  Nothing here is secret. The UID is printed in the silicon.")
print("  The owner did nothing wrong at any point.")
print()

print("=" * 70)
print("WHAT THE ATTACKER HAS TO GUESS")
print("=" * 70)
uid_space   = 1 << UID_BITS
timer_space = 1 << TIMER_BITS
print(f"  1. Which chip made it?")
print(f"     He does not know it is 0x{EXAMPLE_UID:08X}. He must try every one:")
print(f"     {uid_space:>20,}  possible UIDs        (2^{UID_BITS})")
print()
print(f"  2. Exactly when was it set up?")
print(f"     He can bound it to about an hour, so the timers are nearly pinned:")
print(f"     {timer_space:>20,}  timer states         (2^{TIMER_BITS})")
print()
total = uid_space * timer_space
print(f"  TOTAL COMBINATIONS TO TRY")
print(f"     {uid_space:,}  x  {timer_space:,}")
print(f"     = {total:,}")
print(f"     = 2^{UID_BITS + TIMER_BITS}")
print()

print("=" * 70)
print("AND THEN WE GET THIS PICTURE")
print("=" * 70)
GPU_RATE = 54_443_902_652     # measured on a free Colab T4, this episode's notebook
designed = 1 << 128
print(f"  what he actually has to search :  {total:>44,}")
print(f"  what the DESIGN promised       :  {designed:>44,}")
print()
print(f"  on the free Colab T4 we just ran ({GPU_RATE:,} ops/sec):")
print(f"     2^{UID_BITS+TIMER_BITS:<3} -> {total/GPU_RATE:>12,.1f} seconds")
print(f"     2^128 -> {designed/GPU_RATE/31_557_600:>12.3g} years")
print()
print("  Same chip. Same owner. Same 12 words on the same piece of paper.")
print("  One #ifndef decided which of those two lines he was standing on.")
