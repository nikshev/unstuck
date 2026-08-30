# How look-alike wallet addresses are generated (GPU vanity grinding)

Companion code for the **0xUnstuck** video *"How Scammers Generate Look-Alike Wallet Addresses
(and Why You Check the Middle)"*.

> ## ⚠️ Read this first
> This exists so you can **understand and defend against** address poisoning.
> The demo grinds a vanity address **for yourself** — the legitimate use, like `0xC0FFEE...`.
> **Generating an address that mimics someone else's to trick them into sending you funds is theft.
> Never do it.** There is deliberately **no** poisoning pipeline here (no funding a twin, no
> zero-value transfers to victims) — only the generation mechanism and the math.

## The point in one line

They can cheaply fake the **first few and last few** characters of an address.
They can **never** fake the middle. So check the middle — or better, never copy a send-to address
from your transaction history.

## How generation actually works

It is brute force, not broken cryptography:

1. make a random key pair
2. derive its address
3. compare **only** the characters a human actually looks at (the ends)
4. no match → throw it away and loop

Every guess is independent, which is why GPUs are so effective at it (embarrassingly parallel).

## Run it

**Google Colab** (no install): open `vanity_demo.ipynb`, run the cells.

**Locally:**

```bash
pip install eth-account
python vanity_demo.py
```

## Real output (this laptop, pure Python, ~511 addresses/sec)

```
  0xa    FOUND  0xa9b08d9c6373865e0715e7a6A6193d535B17855e
              25 tries ·  0.05s
  0xab   FOUND  0xaBAb68383fF4C2F97F5ad16DC907FDF2D832fF74
             108 tries ·  0.21s
  0xabc  FOUND  0xaBC7d53B3f917a625C2314eFf058aff8E6AFb64D
             946 tries ·  1.85s

  extrapolating the SAME loop:
    4 chars                      ~6.55e+04 tries   ->  2 minutes
    6 chars                      ~1.68e+07 tries   ->  9 hours
    8 chars                      ~4.29e+09 tries   ->  97 days
    10 chars                     ~1.10e+12 tries   ->  68.3 years
    40 chars (the WHOLE address) ~1.46e+48 tries   ->  9.07e+37 years
```

Each extra hex character multiplies the work by **16**. A GPU rig is millions of times faster —
which moves the *ends* into seconds, and the *full address* nowhere at all.

## Your defence, ranked

1. **Never** copy a send-to address from your transaction history
2. Save trusted addresses in your wallet's **address book / whitelist**
3. If you verify by eye, check the **middle**, not just the ends
4. Big transfer? Send a small **test amount** first, confirm, then send the rest

## A caution about vanity tools

Public grinders (`vanitygen`, `profanity`) were written years ago for fun addresses.
`profanity` turned out to have **weak randomness**, and attackers later used that flaw to drain
wallets created with it. Grinding your own vanity key carries real risk — treat any such key as
lower-security.

---
Full breakdown of the attack itself: the **Address Poisoning** video on the channel.
