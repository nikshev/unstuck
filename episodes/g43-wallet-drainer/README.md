# g43 — Crypto Wallet Drainers: One Signature

Companion code for the video: https://www.youtube.com/channel/UC32d5uV5MEC1oMqVaVbQPNA

A wallet drainer does not steal your seed phrase. It asks you to **sign one message**. Nothing
visible happens. The wallet empties hours or days later, and the transaction that moves your money
is valid and was authorised by you.

## What this code is — and is not

> ✅ **This is a DEFENSIVE tool.** `decode_permit.py` takes the EIP-712 typed data a site asks you to
> sign and prints, in plain English, what you would be granting. It **signs nothing, sends nothing,
> needs no key and touches no network.** There is no exploit here and nothing that could be pointed
> at anyone.

## Run it

```bash
python3 keccak.py          # self-test against the standard Keccak-256 vectors
python3 decode_permit.py   # decode the permit (no dependencies, no network)
```

## The digests are real, and you can check that

Ethereum uses the **original Keccak padding (0x01)**, not NIST SHA-3's (0x06), so
`hashlib.sha3_256` produces a *different* digest and cannot stand in for it. `keccak.py` implements
Keccak-256 in ~50 lines of pure Python and self-tests against the published vectors:

```
keccak256(b"")    = c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470
keccak256(b"abc") = 4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45
```

And the EIP-712 encoding is verified end-to-end: the domain separator the decoder derives for USDC
matches the value published on the real contract —

```
06c37168a7db5138defc7866392bb87a741f9b3d104deb5094588ce041cae335
```

So the hash the demo shows is the same 32 bytes a wallet would show you, not an illustration.

## What the output demonstrates

```
WHAT YOUR HARDWARE WALLET SHOWS YOU (blind signing)
   0xf46bfc07835b173d699a5e9005f8e1720a308c6f183eefbee4e6bc6cd8948855

WHAT YOU ARE ACTUALLY SIGNING
   token                  USD Coin  (0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)
   you are granting       0xBAdC0ffee0000000000000000000000000000bAd
   permission to spend    EVERYTHING — unlimited, the maximum a uint256 can hold
   expires                NEVER — this permission does not expire
   costs you in gas       nothing — it is an off-chain signature
   visible on-chain       no, not until the attacker chooses to use it
```

Both panels describe the same 32 bytes. One of them is readable.

## The three permissions

| | what it grants | note |
|---|---|---|
| `approve(spender, amount)` | a token allowance | normal and necessary — the problem is that "unlimited" is the convenient ask |
| `setApprovalForAll(operator)` | an entire NFT collection | including items you buy later |
| `permit(...)` | the same spending power, **as a signature** | no gas, no history, nothing on chain until redeemed |

## The numbers, with their caveats

- Ethereum drainer-as-a-service study (Mar 2023 – Apr 2025): **~$135M across 76,582 victim wallets**,
  split **$23.1M to kit operators / $111.9M to affiliates**.
- **83.5% of victim accounts lost under $1,000.** It is a volume business, not a whale hunt.
- Inferno Drainer takes a **20% commission**; Angel + Inferno + Pink accounted for **93.9%** of
  measured profits in a 2025 study.
- Scam Sniffer: **~$494M in 2024** across 332,000+ addresses.

⚠️ **These come from different studies with different scopes and methods — do not add them together
or read them as one trend line.** There is no verified full-year 2026 total. Even a single family is
disputed: Inferno has been reported at ~$6M by one firm and >$70M by another.

⚠️ **The January 2026 ~$285M hardware-wallet theft was NOT a drainer.** That was social engineering
aimed at the seed phrase — a different attack with a different defence. The coverage blurs the two
constantly, and the blurring is harmful.

## What actually works

1. Arrive at applications from **your own bookmarks** — never a link in a message, reply or ad.
2. Treat **"unlimited"** as the red flag; set the limit to what you are actually spending.
3. Refuse any **permit you did not initiate**, and any signature your wallet cannot put into words.
   If it shows a hash, that is the warning, not a formality.
4. **Revoke old approvals** — the ones from years ago are still live.
5. **Simulate before you confirm.**

## Sources

- Group-IB, crypto wallet drainers — https://www.group-ib.com/resources/knowledge-hub/crypto-wallet-drainers/
- BlockSec, the $135M drainer-as-a-service economy — https://blocksec.com/blog/inside-ethereum-s-shadow-economy-new-research-unmasks-the-135-m-drainer-as-a-service-industry
- EIP-712 — https://eips.ethereum.org/EIPS/eip-712
- EIP-2612 (permit) — https://eips.ethereum.org/EIPS/eip-2612

## The question the video ends on

Has your wallet ever shown you a bare hash, and you approved it anyway?
