"""What you APPROVE and what you SIGN are two different objects.

This is a MODEL of the Bitget mechanism (24 Sep 2026), not Bitget's code — none of their internals
are public. It contains no exploit: it signs nothing real, touches no network, and produces no
transaction any chain would accept. It exists to make one boundary visible.

The point: in a custody pipeline, the thing that BUILDS a withdrawal and the thing that DISPLAYS it
for approval are usually the same backend. The signer then signs the bytes it was handed. Nobody
ever compares the sentence a human approved against the bytes that got signed — and nothing in the
cryptography requires them to match.

Run:  python3 what_you_sign.py      (no dependencies, no network)
"""
import hashlib, hmac

# A stand-in for the signing key. Real custody uses ECDSA/threshold signatures; the mechanism below
# does not depend on which, so a keyed hash keeps the demo readable and dependency-free.
SIGNING_KEY = b"hardware-signer-secret"


def serialize(tx):
    """The bytes that actually get signed."""
    return f"{tx['asset']}|{tx['amount']}|{tx['to']}".encode()


def sign(tx):
    return hmac.new(SIGNING_KEY, serialize(tx), hashlib.sha256).hexdigest()


def verify(tx, sig):
    return hmac.compare_digest(sign(tx), sig)


def summary_for_human(view):
    """What the approval screen renders. Note the argument: it is NOT the signed object."""
    return f"Send {view['amount']} {view['asset']} to {view['to']}"


def approve_and_sign(tx, view):
    """The flow, exactly as it is usually built: a human reads `view`, clicks approve,
    and the signer signs `tx`. The two are never compared to each other."""
    print("   approver sees :", summary_for_human(view))
    print("   signer signs  :", serialize(tx).decode())
    sig = sign(tx)
    print("   signature valid over the signed bytes?", verify(tx, sig))
    return sig


print("=" * 72)
print("1. HEALTHY — the backend builds one object and shows that same object")
print("=" * 72)
tx = {"asset": "ETH", "amount": "12.0", "to": "0xTreasuryCold...9f21"}
approve_and_sign(tx, tx)                      # same dict passed twice: one source of truth

print()
print("=" * 72)
print("2. COMPROMISED BACKEND — it shows the old object, signs a new one")
print("=" * 72)
print("   The attacker never touches the key, the signer, or the signature.")
print("   They only change which object reaches which side.")
spoofed = {"asset": "ETH", "amount": "87600.0", "to": "0xAttacker......beef"}
sig = approve_and_sign(spoofed, tx)           # human sees `tx`, signer signs `spoofed`

print()
print("-" * 72)
print("Every cryptographic statement here is TRUE:")
print("  the signature verifies            ->", verify(spoofed, sig))
print("  it was made by the real key       -> yes")
print("  the approval step completed       -> yes")
print("  the approver authorised THIS move ->", summary_for_human(tx) == summary_for_human(spoofed))
print()
print("Nothing was forged. The signature is honest about the bytes it covers.")
print("It simply never promised that those bytes are the ones a human agreed to.")
