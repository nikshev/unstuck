#!/usr/bin/env python3
"""Why gluing variable-length fields together makes two different things look identical.

This is the SHAPE of the Liquid Network cache-key bug (Elements, Sept 2026, ~$320M).
It is not Elements source — it is the minimum code that shows why the key collided.

Elements concatenated four variable-length components — range proof, value commitment,
asset generator, output script — with NO delimiters. The ambiguity lives between any two
ADJACENT variable-length fields: nothing records where one ends and the next begins.
Modelled below with the two that vary in the attack: the range proof and the script.

    python3 cache_collision.py
"""
import hashlib

def key_broken(proof: bytes, script: bytes) -> bytes:
    return proof + script                    # no length, no separator, no domain tag

def key_fixed(proof: bytes, script: bytes) -> bytes:
    return hashlib.sha256(b"".join(len(p).to_bytes(4, "big") + p
                                   for p in (proof, script))).digest()

# TX A — legitimate. A proof that really verifies, plus a 67-byte OP_RETURN script.
SCRIPT_A = bytes(range(67))                  # the 67 bytes the attacker chose
PROOF_A  = b"\xaa" * (4301 - 67)

# TX B — the attack. A DIFFERENT, invalid proof that simply ENDS WITH those same 67 bytes,
# and an empty script. The boundary moved 67 bytes to the right. Nothing else changed.
PROOF_B  = PROOF_A + SCRIPT_A
SCRIPT_B = b""

def show(name, proof, script):
    k = key_broken(proof, script)
    print(f"  {name}")
    print(f"     proof {len(proof):>5} B   +   script {len(script):>3} B")
    print(f"     key:  {len(k):,} bytes   sha256 {hashlib.sha256(k).hexdigest()[:32]}…")
    return k

print("=" * 78)
print("1. TWO DIFFERENT TRANSACTIONS")
print("=" * 78)
a = show("TX A — legitimate (this proof really verifies)", PROOF_A, SCRIPT_A)
print()
b = show("TX B — the attack (invalid proof, empty script)", PROOF_B, SCRIPT_B)

print("\n" + "=" * 78)
print("2. THE CACHE KEY")
print("=" * 78)
print(f"  identical?   {a == b}")
print(f"  both are     {len(a):,} bytes")
print(f"  same sha256  {hashlib.sha256(a).hexdigest()[:40]}…\n")
print("  Nothing was forged and no cryptography was broken. The boundary between")
print("  'where the proof ends' and 'where the script begins' is not recorded")
print("  anywhere — so moving it 67 bytes produces the identical stream.\n")

print("=" * 78)
print("3. WHY THAT IS FATAL HERE")
print("=" * 78)
print("""  The lookup happened BEFORE the cryptography:

      if (cache.contains(key)) return true;      <- answers here
      parse_commitments(...);                    <- never reached
      secp256k1_rangeproof_verify(...);          <- never reached

  TX A is verified honestly once, and its key is stored. Sixty seconds later
  TX B arrives, produces the SAME key, hits the cache and is told "already
  verified" — without one elliptic-curve operation being performed.
""")

print("=" * 78)
print("4. THE FIX — length-prefix every field, then hash")
print("=" * 78)
fa, fb = key_fixed(PROOF_A, SCRIPT_A), key_fixed(PROOF_B, SCRIPT_B)
print(f"  TX A -> {fa.hex()[:48]}…")
print(f"  TX B -> {fb.hex()[:48]}…")
print(f"  identical?   {fa == fb}\n")
print("  Four bytes of length in front of each field. That is the whole fix:")
print("  'where does this field end' becomes written down instead of guessed.\n")
print("  Blockstream shipped it in Elements v23.3.4 as 'hardened range-proof cache keys'.")
print("  The same fix was merged to master on 1 September — five days before the attack —")
print("  but no tagged release carrying it had reached a production node.\n")
