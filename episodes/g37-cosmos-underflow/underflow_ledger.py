#!/usr/bin/env python3
"""Why "it subtracted past zero" is not a rounding error — it rewrites the ledger.

Models the SHAPE of the Cosmos EVM staking-precompile defect: a balance write-back done in
unsigned 256-bit arithmetic without a check. This is not Cosmos source; it is the minimum
code needed to show what the machine actually believes afterwards.
"""
MAX = (1 << 256) - 1
def u256(x: int) -> int:
    """Unsigned 256-bit wrap — exactly what the machine does, no error, no exception."""
    return x & MAX

ONE_KII = 10**18
ledger = {"attacker": 2 * ONE_KII, "victim": 900_000 * ONE_KII}

def show(title):
    print(f"\n  {title}")
    for who, bal in ledger.items():
        print(f"    {who:<9} {bal:>78,}")

print("=" * 96)
print("THE CODE — the same write-back, with and without one check")
print("=" * 96)
print("""
  VULNERABLE                              HARDENED
  ----------------------------            ----------------------------
  new = u256(balance - amount)            if amount > balance:
  store(addr, new)                            revert("insufficient")
                                          store(addr, balance - amount)
""")
print("  In Solidity 0.8 the compiler inserts that check for you.")
print("  In a Go precompile below the EVM, nobody does. You write it, or it isn't there.\n")

show("1. STATE BEFORE  (attacker holds exactly 2 KII)")

print("\n" + "=" * 96)
print("2. THE SUBTRACTION — delegate 2 KII + ONE WEI")
print("=" * 96)
amount = 2 * ONE_KII + 1
bal = ledger["attacker"]
print(f"    balance  {bal:>78,}")
print(f"  - amount   {amount:>78,}")
print(f"  = true     {bal - amount:>78,}   <- negative. There is no negative.")
ledger["attacker"] = u256(bal - amount)
print(f"  = STORED   {ledger['attacker']:>78,}")

show("   STATE AFTER")

print("\n" + "=" * 96)
print('3. "SO WHAT?" — because that number IS the ledger')
print("=" * 96)
print("  Every downstream check reads it and answers honestly:\n")
for label, ask in (("can he send 1 KII?", ONE_KII),
                   ("can he send 1,000,000 KII?", 1_000_000 * ONE_KII),
                   ("can he send 10^30 KII?", 10**30 * ONE_KII)):
    ok = ledger["attacker"] >= ask
    print(f"    require(balance >= {ask:<40,})   ->   {'PASS' if ok else 'FAIL'}   {label}")
print("\n  Nothing is broken. Nothing is bypassed. The check works perfectly")
print("  and returns the right answer about a number that is a lie.\n")

print("=" * 96)
print('4. "SO WHAT IF YOU SEND IT?" — a transfer is the only op that touches TWO rows')
print("=" * 96)
print("  An impossible number in your own row is not money. To become money it")
print("  has to move — and the receiving side wraps too, in the other direction.\n")
v = ledger["victim"]
send = MAX - v + 1          # pushes the victim's row exactly over the ceiling
print(f"    victim balance    {v:>78,}")
print(f"  + incoming          {send:>78,}")
print(f"  = true sum          {v + send:>78,}   <- over the 2^256 ceiling")
ledger["victim"] = u256(v + send)
print(f"  = STORED            {ledger['victim']:>78,}")
show("   STATE AFTER")
print("\n  The victim's 900,000 KII is gone from the ledger without a single token")
print("  being minted or burned. Supply is unchanged. Ownership is not.")
print("\n  Per Cosmos Labs: no additional tokens were created and total supply")
print("  remained effectively unchanged. That is exactly what a wrap does — it")
print("  moves value between rows instead of creating it.\n")
