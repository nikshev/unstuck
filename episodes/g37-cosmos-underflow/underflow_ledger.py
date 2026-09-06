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
print('4. "OK, THE VICTIM IS AT ZERO. WHAT DO I GET?"')
print("=" * 96)
print("  Nothing — if it stopped there. A wrapped balance in your own row is not money,")
print("  and destroying someone else's row does not pay you either.")
print()
print("  What KiiChain's post-mortem actually describes is a DEBIT/CREDIT PAIR:")
print("  the same underflowed delegation debits a victim address AND credits the")
print("  attacker's helper address with the same amount. Value moves, it is not burned.\n")
STOLEN = 900_000 * ONE_KII
ledger["victim"]   = u256(ledger["victim"] - STOLEN)
ledger["attacker"] = STOLEN          # the helper row now holds REAL, spendable KII
show("   LEDGER AFTER ONE ROUND (attacker row = real tokens, not a wrapped number)")
print(f"\n  KiiChain: this exact workflow was repeated 18 times against different targets.")
print(f"  Total moved: 148,326,583.15 KII\n")

print("=" * 96)
print("5. AND *THIS* IS THE PAYDAY — the part that happens off this chain")
print("=" * 96)
steps = [
  ("helper address -> attacker's primary KiiChain address", "a second EVM tx to the same helper contract"),
  ("bridge OUT via Hyperlane to BNB Smart Chain",           "67,597,997.87 KII  (45.6%)"),
  ("sell on PancakeSwap",                                   "64,597,997.87 KII into the pool"),
  ("deposit to a CEX",                                      "3,000,000 KII to a KuCoin address"),
  ("REALISED",                                              "about $1,600,000"),
]
for a,b in steps:
    print(f"    {a:<52} {b}")
print()
print("  Inflated KII on KiiChain is a number in a database the victims' own chain controls.")
print("  It only becomes money once it is somewhere that chain cannot reach, sold to")
print("  somebody who pays in an asset nobody can freeze.")
print()
print("  Proof that this is the real bottleneck: KiiChain halted at block 9355723 and")
print("  80,728,575.06 KII - 54.4% of the theft - never left the chain and is still frozen.")
print("  Same exploit, same balances. The half that had not been SOLD yet was worth nothing.\n")
