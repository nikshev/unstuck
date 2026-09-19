# g39 — Rug Pulls: The 5 Lines of Code That Take Your Money

A rug pull is **not a hack**. Nothing is broken into and no vulnerability is found — the team uses a
power the contract granted them on purpose, before anyone bought. That is why, unlike almost every
other incident on this channel, it is visible **in advance**, in public, to anyone who reads the source.

## How common

A 2026 study of **three Solana DEXs** examined **100,063** tokens issued in **early 2025** and flagged
**76,469** as rug-pull *candidates*. (Three exchanges, one chain, one period, and *candidate* means
structural markers — not that each was proven.) Average taken per rug pull in 2025: **~$510,000**.
**70% of victims lost under $10,000** each.

## The five patterns

| # | pattern | what it gives the team |
|---|---|---|
| 1 | uncapped `mint` | new supply whenever they want |
| 2 | a switch on selling | you can buy; you may not be able to leave |
| 3 | a fee with no ceiling | a 100% sell tax rugs without touching the pool |
| 4 | owner can pull liquidity | the token lives, the market does not |
| 5 | an upgrade path | today's code is not tomorrow's code |

**None of these is a bug.** Each is a deliberate capability, and in an honest project several exist for
good reasons. The question is never *does this power exist* — it is **is it bounded, and by what**.

## ⭐ The distinction that matters: a `require()` is not a limit

```solidity
// ACCESS CONTROL — says WHO may mint                 // AN ACTUAL CAP — says HOW MUCH may exist
function mint(address to, uint256 amt) {             function mint(address to, uint256 amt) {
  require(msg.sender == owner);                        require(totalSupply() + amt <= MAX, "cap");
  _mint(to, amt);                                      _mint(to, amt);
}                                                    }
```

Both have a `require`. Only one has a limit. The left one passes happily while the owner mints a
billion tokens, *because the owner is indeed the owner*.

The common advice — "look for require statements", "check the function is protected" — is not merely
incomplete, it **misleads**: the protected function is exactly the one that takes your money.

**This is not theoretical.** The checker in this folder got it wrong on its first run: the rule asked
*is there a require?*, saw the access-control check, and cleared an uncapped mint. It now asks whether
the require compares the **amount** against a maximum. The fix is visible in `rug_check.py`.

## Run it

```bash
python3 rug_check.py --demo        # bundled good/bad examples
python3 rug_check.py token.sol     # your own verified source
```

No API key, no account, no network. Full output: [`run.log`](run.log).

```
EXAMPLE A — a token built to be exited
  [CRITICAL]  UNCAPPED MINT
  [CRITICAL]  SELL BLOCK / HONEYPOT
  [CRITICAL]  UNBOUNDED FEE
  [CRITICAL]  OWNER CAN PULL LIQUIDITY
  -> 4 red flag(s).

EXAMPLE B — the same functions, bounded
  [    good]  renounceOwnership
  [    good]  hard-capped supply
  -> no red flags in these five patterns.
```

Both contracts can mint. Both have a fee. **The entire difference is what is bounded.**

## ⚠️ What this does NOT do

A clean result means *these five patterns were not found*. It does **not** mean a token is safe.

Soft rugs — where the team quietly sells down and stops working — grew **35%** and now outnumber hard
ones, and they frequently involve **no illegal code at all**. No source analysis can catch that. Any
scanner claiming otherwise is selling something.

## Sources
deepstrike.io & coinlaw.io rug-pull statistics 2026 · the Solana token study · Sumsub · NFT Plazas

## Related
- [`../g35`](../) *They Passed the Audit* — why a clean report certifies a moment, not a promise
- [`../g34-coldcard`](../g34-coldcard) — the opposite case: a failure that really was a bug
