# g41 — The Bitget Hack: $387M, No Keys Stolen

Companion code for the video: https://www.youtube.com/channel/UC32d5uV5MEC1oMqVaVbQPNA

On **24 September 2026**, about **$387.5 million** left the exchange Bitget in roughly forty-five
minutes. No private key was stolen. Every signature was genuine, produced by the real signing key,
and approved by Bitget's own process.

## What this code is — and is not

> ⚠️ **This is an illustrative MODEL of a trust boundary, not Bitget's code.** Their internals are
> not public. It contains **no exploit**: it signs nothing real, touches no network, and produces no
> transaction any chain would accept. It exists to make one boundary visible in about thirty lines.

## The boundary

A withdrawal is three steps, done by three systems:

1. **BUILD** — a backend writes the unsigned transaction (which wallet pays, how much, to whom).
2. **APPROVE** — rules are checked; for large amounts a human reads a summary and clicks approve.
3. **SIGN** — a signer applies the key, usually in a dedicated hardware module.

That separation is good design: no single machine both decides to move money and authorises it.

**But:** the *sentence* the human approves and the *bytes* that get signed are **both produced by the
backend**, and nothing downstream ever compares them to each other. The signer has no independent
notion of a correct withdrawal — it signs what it is handed, having confirmed only that the request
came from the authorised internal system.

While the backend is honest, this is invisible. The moment it lies, every control after it keeps
working perfectly — and approves the lie.

## Run it

```bash
python3 what_you_sign.py        # no dependencies, no network
```

Output (the part that matters):

```
COMPROMISED BACKEND — it shows the old object, signs a new one
   approver sees : Send 12.0 ETH to 0xTreasuryCold...9f21
   signer signs  : ETH|87600.0|0xAttacker......beef
   signature valid over the signed bytes? True

Every cryptographic statement here is TRUE:
  the signature verifies            -> True
  it was made by the real key       -> yes
  the approval step completed       -> yes
  the approver authorised THIS move -> False
```

Four questions, three reassuring answers, and only the fourth one mattered — and it is the only one
the system was never built to ask.

## What actually happened

- **Entry:** a vulnerability in a **third-party security product** Bitget ran internally yielded
  high-level credentials for the company network. A supply-chain compromise, not cryptography.
  Bitget has not named the product, so neither do we.
- **Mechanism:** transactions were forged at the infrastructure level **before** signing, then, in
  Bitget's own words, *"routed through the legitimate transaction approval process. Since they looked
  legitimate, they were automatically approved without raising alerts."*
- **Timeline (UTC):** 18:31 detection across several chains → ~19:01 first drain **$87.6M** →
  19:16 second wave **$202.8M**.
- **Split:** ~$100M swapped straight to ETH (USDT/USDC can be frozen by their issuers; ETH cannot),
  $85M already ETH, $157.5M XRP, $7M TRX.
- **Laundering:** TRON → USDT0 → Ethereum → THORChain → BTC → a Wasabi CoinJoin round; Tornado Cash
  also in the path. **NEAR Intents and Chainflip refused to route the funds.**
- **Aftermath:** covered by Bitget's **$464M User Protection Fund**; withdrawals restored BTC 28 Sep,
  ETH 29 Sep, USDT 30 Sep, the rest 2 Oct. 5% bounty to freeze, 5% to recover.

**Two loss figures circulate:** TRM Labs published **$351.6M**, Bitget confirmed **$387.5M**. They
were measured at different moments as assets moved. We use Bitget's own confirmed number.

**Attribution:** CEO Gracy Chen said North Korea was *"very likely"* responsible; TRM Labs reached the
same conclusion independently. That is attribution, not a courtroom verdict.

## Sources

- Bitget incident page — https://www.bitget.com/academy/bitget-security-incident-what-happened-timeline-impact-response
- Halborn, technical analysis — https://www.halborn.com/blog/post/explained-the-bitget-hack-september-2026
- TRM Labs — https://www.trmlabs.com/resources/blog/bitget-loses-usd-3516-million-in-hot-wallet-breach-in-likely-north-korea-attack
- CryptoSlate, on the 30-minute window — https://cryptoslate.com/bitget-had-30-minutes-to-contain-its-hack-before-290-million-started-moving/
- Cryptopolitan, on the refused laundering routes — https://www.cryptopolitan.com/bitget-laundering-near-intents-chainflip/

## The question the video ends on

When a human approves an action on your system, is there anything that **independently** checks that
what got executed is what they saw? If the answer takes more than a moment, that is the interesting
part.
