#!/usr/bin/env python3
"""Why 40 bits of entropy is fatal — demonstrated end to end on a DELIBERATELY WEAK
wallet that this script creates itself.

WHAT THIS IS:  a measurement. It builds a BIP39 wallet whose entropy is restricted to a
tiny space (default 2^20), then finds it again by exhaustive search, and reports the real
throughput. From that measured rate it extrapolates to 40 bits (the Coldcard case) and to
128 bits (the design target).

WHAT THIS IS NOT:  it does not reconstruct any device's RNG state, it does not touch any
real wallet, and it cannot recover anyone's funds. The only wallet it can find is the one
it just generated, because we chose to make it weak.

Run:  python3 seed_search.py            # default 20-bit demo
      python3 seed_search.py --bits 22
      python3 seed_search.py --cost      # compare prefix-check vs seed-check cost
"""
import argparse, hashlib, hmac, struct, sys, time
from mnemonic import Mnemonic
from ecdsa import SigningKey, SECP256k1

MNEMO = Mnemonic("english")


def weak_entropy(i: int, bits: int) -> bytes:
    """16 bytes of BIP39 entropy in which only `bits` bits actually vary.

    This is the whole point: a generator that LOOKS like it produces 128-bit entropy, but
    whose real search space is 2**bits. That is exactly the shape of the Coldcard failure —
    the output was a normal-looking seed; the space it was drawn from was tiny.
    """
    if i >= (1 << bits):
        raise ValueError("index outside the weak space")
    # stretch the small counter over 16 bytes so the result is indistinguishable by eye
    return hashlib.sha256(struct.pack(">Q", i)).digest()[:16]


def entropy_to_address(entropy: bytes) -> tuple[str, str]:
    """BIP39 -> seed -> BIP32 master key -> compressed pubkey fingerprint.

    Every step here is the standard, public math every wallet runs. Nothing secret.
    """
    words = MNEMO.to_mnemonic(entropy)                      # 12 words
    seed = MNEMO.to_seed(words)                             # PBKDF2-HMAC-SHA512, 2048 rounds
    I = hmac.new(b"Bitcoin seed", seed, hashlib.sha512).digest()
    priv = I[:32]                                           # BIP32 master private key
    vk = SigningKey.from_string(priv, curve=SECP256k1).verifying_key
    p = vk.pubkey.point
    pub = bytes([2 + (p.y() & 1)]) + p.x().to_bytes(32, "big")   # compressed pubkey
    h160 = hashlib.new("ripemd160", hashlib.sha256(pub).digest()).hexdigest()
    return words, h160


def search(target: str, bits: int, report_every: int = 250):
    space = 1 << bits
    t0 = time.time()
    for i in range(space):
        _, h160 = entropy_to_address(weak_entropy(i, bits))
        if h160 == target:
            return i, time.time() - t0, i + 1
        if (i + 1) % report_every == 0:
            el = time.time() - t0
            print(f"    tried {i+1:>9,} / {space:,}   "
                  f"{(i+1)/el:8.1f} checks/s   {el:6.1f}s", flush=True)
    return None, time.time() - t0, space


def human(seconds: float) -> str:
    for unit, n in (("years", 31557600), ("days", 86400), ("hours", 3600),
                    ("minutes", 60), ("seconds", 1)):
        if seconds >= n:
            v = seconds / n
            return f"{v:,.1f} {unit}" if v < 1e6 else f"{v:.3g} {unit}"
    return f"{seconds*1000:.1f} ms"


def cost_comparison():
    """Measure how much dearer a real seed check is than g31's address-prefix check."""
    N = 2000
    t0 = time.time()
    for i in range(N):
        hashlib.sha256(struct.pack(">Q", i)).hexdigest()[:8].startswith("dead")
    prefix_rate = N / (time.time() - t0)

    N2 = 200
    t0 = time.time()
    for i in range(N2):
        entropy_to_address(weak_entropy(i, 20))
    seed_rate = N2 / (time.time() - t0)

    print("\n  COST OF ONE CHECK — measured on this machine")
    print(f"    cheap prefix compare (what our GPU demo counted): {prefix_rate:12,.0f} /s")
    print(f"    full BIP39 seed -> key -> address check:          {seed_rate:12,.0f} /s")
    print(f"    a real seed check is  ~{prefix_rate/seed_rate:,.0f}x  more expensive\n")
    return seed_rate


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--bits", type=int, default=20, help="size of the weak space (2**bits)")
    ap.add_argument("--cost", action="store_true", help="only run the cost comparison")
    a = ap.parse_args()

    if a.cost:
        cost_comparison(); return

    print(f"\n=== 1. Create a wallet from a DELIBERATELY WEAK generator ({a.bits} bits) ===")
    secret_index = (1 << a.bits) - 7          # fixed so the run is reproducible
    words, target = entropy_to_address(weak_entropy(secret_index, a.bits))
    print(f"    mnemonic : {words}")
    print(f"    hash160  : {target}")
    print(f"    (looks like any other 12-word wallet — nothing about it appears weak)")

    print(f"\n=== 2. Search the whole space for it ===")
    print(f"    space = 2^{a.bits} = {1 << a.bits:,} candidates")
    found, elapsed, tried = search(target, a.bits)
    if found is None:
        print("    NOT FOUND (should be impossible)"); sys.exit(1)
    rate = tried / elapsed
    print(f"\n    FOUND at index {found:,} after {tried:,} tries in {elapsed:.1f}s")
    print(f"    measured rate: {rate:,.0f} full seed checks / second (single CPU core)")

    print(f"\n=== 3. What that rate means for real entropy sizes ===")
    print(f"    {'entropy':>10}  {'search space':>26}  {'time at this rate':>22}")
    for bits in (a.bits, 32, 40, 48, 64, 128):
        space = 1 << bits
        print(f"    {bits:>7} b  {space:>26,}  {human(space / rate):>22}")
    print(f"\n    Coldcard Mk2/Mk3 on fw 4.0.0-4.1.9 landed at ~40 bits.")
    print(f"    The design target was 128.\n")


if __name__ == "__main__":
    main()
