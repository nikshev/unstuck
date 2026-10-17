"""Decode an EIP-712 Permit the way your wallet SHOULD show it — and the hash it shows instead.

This is a DEFENSIVE tool. It contains no attack: it signs nothing, sends nothing, needs no key and
touches no network. It takes the typed-data blob a site asks you to sign and prints, in plain
English, what you would be granting.

The EIP-712 digest is computed for real (see keccak.py, self-tested against the standard vectors),
so the hash printed here is the same 32 bytes a hardware wallet shows you when it cannot decode the
message — which is the entire problem.

Run:  python3 decode_permit.py        (no dependencies, no network)
"""
from keccak import keccak256

MAX_UINT256 = (1 << 256) - 1

# Exactly the shape a site sends to eth_signTypedData_v4.
TYPED_DATA = {
    "domain": {
        "name": "USD Coin", "version": "2", "chainId": 1,
        "verifyingContract": "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",   # real USDC
    },
    "primaryType": "Permit",
    "types": {
        "EIP712Domain": [("name", "string"), ("version", "string"),
                         ("chainId", "uint256"), ("verifyingContract", "address")],
        "Permit": [("owner", "address"), ("spender", "address"), ("value", "uint256"),
                   ("nonce", "uint256"), ("deadline", "uint256")],
    },
    "message": {
        "owner": "0x1111111111111111111111111111111111111111",     # you
        "spender": "0xBAdC0ffee0000000000000000000000000000bAd",    # the drainer's contract
        "value": MAX_UINT256,                                       # <- everything, forever
        "nonce": 0,
        "deadline": MAX_UINT256,
    },
}


def enc_type(types, primary):
    fields = ",".join(f"{t} {n}" for n, t in types[primary])
    return f"{primary}({fields})".encode()


def enc_value(typ, val):
    if typ == "string":
        return keccak256(val.encode())
    if typ == "address":
        return bytes(12) + bytes.fromhex(val[2:])
    if typ.startswith("uint"):
        return val.to_bytes(32, "big")
    raise ValueError(typ)


def hash_struct(types, primary, data):
    out = keccak256(enc_type(types, primary))
    for name, typ in types[primary]:
        out += enc_value(typ, data[name])
    return keccak256(out)


def eip712_digest(td):
    domain_sep = hash_struct(td["types"], "EIP712Domain", td["domain"])
    msg_hash = hash_struct(td["types"], td["primaryType"], td["message"])
    return keccak256(b"\x19\x01" + domain_sep + msg_hash)


def human(td):
    m, d = td["message"], td["domain"]
    amount = ("EVERYTHING — unlimited, the maximum a uint256 can hold"
              if m["value"] == MAX_UINT256 else f"{m['value']}")
    until = "NEVER — this permission does not expire" if m["deadline"] == MAX_UINT256 else str(m["deadline"])
    return [
        ("token",            f"{d['name']}  ({d['verifyingContract']})"),
        ("you are granting", m["spender"]),
        ("permission to spend", amount),
        ("expires",          until),
        ("costs you in gas", "nothing — it is an off-chain signature"),
        ("visible on-chain", "no, not until the attacker chooses to use it"),
    ]


if __name__ == "__main__":
    digest = eip712_digest(TYPED_DATA)

    print("=" * 74)
    print("WHAT YOUR HARDWARE WALLET SHOWS YOU (blind signing)")
    print("=" * 74)
    print(f"\n   Sign this message?\n\n   0x{digest.hex()}\n")
    print("   [ Reject ]                                            [ Approve ]\n")

    print("=" * 74)
    print("WHAT YOU ARE ACTUALLY SIGNING")
    print("=" * 74 + "\n")
    for k, v in human(TYPED_DATA):
        print(f"   {k:22} {v}")

    print("\n" + "-" * 74)
    print("Both panels describe the SAME 32 bytes. One of them is readable.")
    print("No transaction is sent when you sign this. Nothing appears in your")
    print("history. The attacker holds the signature and spends it whenever.")
