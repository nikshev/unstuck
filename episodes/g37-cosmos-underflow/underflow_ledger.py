#!/usr/bin/env python3
"""900,000 -> 0 and 2 -> 900,000, step by step, with the arithmetic shown.

Models the SHAPE of the Cosmos EVM defect chain. Not Cosmos source — the minimum code
needed to show why each number lands where it lands.

Mechanism per Cosmos Labs' post-mortem:
  * the EVM StateDB tracks only an account's SPENDABLE balance
  * a vesting account in SDK state holds spendable AND locked
  * x/staking and the staking precompile both allow the LOCKED portion to be delegated
  * so a vesting account can delegate MORE than its spendable balance, and the
    post-delegation write-back subtracts the full amount from the smaller figure, unchecked
"""
MAX = 1 << 256
def u256(x): return x % MAX          # what the machine does: wrap, silently

ONE = 10**18
def kii(x): return f"{x/ONE:,.0f} KII" if x % ONE == 0 else f"{x:,} akii"

print("=" * 78)
print("STEP 0 — why it has to be a VESTING account")
print("=" * 78)
print("""
  EVM StateDB           knows ONE number:   spendable
  SDK vesting account   holds TWO numbers:  spendable + locked

  x/staking and the staking precompile let you delegate the LOCKED part too.
  So the amount you may delegate can be LARGER than the number the EVM tracks.
  That gap is the whole vulnerability. A normal account cannot do this.
""")
spendable = 2 * ONE
locked    = 50 * ONE
print(f"  attacker's vesting account:  spendable = {kii(spendable)}   locked = {kii(locked)}")
print(f"  EVM StateDB sees only:       {spendable:,} akii\n")

print("=" * 78)
print("STEP 1 — delegate ONE WEI more than spendable")
print("=" * 78)
delegated = spendable + 1
print(f"  delegate  {delegated:,} akii   (2 KII + 1 wei — allowed, the locked part covers it)\n")
print("  the post-delegation write-back does:      spendable - delegated")
print(f"    {spendable:>78,}")
print(f"  - {delegated:>78,}")
print(f"  = {spendable - delegated:>78,}   <- there is no -1 in a uint256")
attacker = u256(spendable - delegated)
print(f"  = {attacker:>78,}   <- STORED  (2^256 - 1)\n")

print("=" * 78)
print("STEP 2 — the transfer that swaps the two balances")
print("=" * 78)
victim = 900_000 * ONE
print(f"  victim's real balance V = {victim:,} akii  ({kii(victim)})\n")
send = MAX - victim
print("  the attacker sends EXACTLY  2^256 - V.  Not a round number - a chosen one.")
print(f"  send S = {send:,}\n")
print("  VICTIM SIDE:      V + S")
print(f"    {victim:>78,}")
print(f"  + {send:>78,}")
print(f"  = {victim + send:>78,}   <- exactly 2^256")
victim_after = u256(victim + send)
print(f"  = {victim_after:>78,}   <- STORED\n")
print("  ATTACKER SIDE:    A - S")
print(f"    {attacker:>78,}")
print(f"  - {send:>78,}")
attacker_after = u256(attacker - send)
print(f"  = {attacker_after:>78,}   <- STORED\n")

print("=" * 78)
print("STEP 3 — read the result")
print("=" * 78)
print(f"  victim    {kii(victim):>16}  ->  {victim_after:,}")
print(f"  attacker  {'2^256 - 1':>16}  ->  {attacker_after:,} akii   = {attacker_after/ONE:,.0f} KII\n")
print(f"  (2^256 - 1) - (2^256 - V)  =  V - 1     the attacker is left with the VICTIM'S balance")
print(f"       V     + (2^256 - V)   =  2^256 = 0  the victim is left with nothing\n")
print("  One transfer. Both sides wrap, in opposite directions, and they NET OUT.")
print("  The fake 78-digit number is consumed; real tokens take its place.")
print("  Nothing minted, nothing burned -> total supply unchanged, exactly as reported.\n")
print(f"  KiiChain: repeated 18 times against different targets = 148,326,583.15 KII")

print("=" * 78)
print('STEP 4 — what "they cancel out" actually means')
print("=" * 78)
print("""
  HIS dial rolled BACKWARD past 0   -> jumped to the top
     the machine INVENTED  + 2^256   that do not exist

  HER dial rolled FORWARD past top  -> fell to 0
     the machine DESTROYED - 2^256   that do not exist

     + 2^256  -  2^256  =  0

  Same invented amount: created once, destroyed once, in the same transaction.
  That is why the chain's books still add up and no alarm fires.

  Take the two phantoms away and look at what is left underneath:
  an ordinary transfer of V, from her account to his. That is all that happened.
""")
