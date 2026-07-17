# DeFi Exploits, Explained — Ep 14: `unchecked` Underflow

## 🎬 Watch

📅 **Premieres Jul 19, 2026.** [Subscribe on YouTube](https://www.youtube.com/channel/UC32d5uV5MEC1oMqVaVbQPNA) to catch it.

A vault drained by a single word: `unchecked`. Since Solidity 0.8, arithmetic **reverts** on
over/underflow automatically — for free. But an `unchecked { }` block turns that safety back off to
save a little gas. Put one security-critical subtraction inside it, subtract more than you have, and
the balance doesn't revert — it **wraps all the way around to ~2^256**. This is a rebuilt, simplified
version of the **Flooring Protocol** hack (Ethereum, June 2026, **~$900K**), whose BT404/DN404 hybrid
token had two accounting paths that disagreed on a fake "ghost-ownership" NFT ID, driving two
`unchecked` underflows. (Yuga Labs white-hatted 68 BAYC/Punks out before the attacker could reach them.)

## The idea in one test
`test/Overflow.t.sol` builds a minimal version:
- `ClaimVaultBuggy` (VULNERABLE) — a vault holding WETH that tracks each user's `credit`. `settle(fee)` does `credit[msg.sender] -= fee` **inside an `unchecked` block**.
- `MockWETH` — a minimal WETH so the vault has a real token to hold and pay out.
- `ClaimVaultFixed` — the one-word fix: the exact same `settle`, with the subtraction **outside** `unchecked` so 0.8's checked math reverts on underflow.

`test_drain` seeds the vault with 100 WETH from other users and gives the attacker **1 WETH of dust**.
The attacker deposits 1 (credit = 1), calls `settle(2)` — `1 - 2` underflows and `credit` wraps to a
**60-digit number** (printed on screen) — then `redeem(101)` passes the `require(credit >= amount)` and
the vault pays out **everything**. `test_fixed` runs the same `settle(2)` against the fixed vault: it
**reverts** (arithmetic underflow), credit stays 1, and the vault keeps its 101 WETH.

> `unchecked` is a loaded gun. Only ever point it at math you can *prove* can't overflow — never at a
> balance an attacker controls.

## Run it yourself
Requires [Foundry](https://getfoundry.sh).

```bash
forge install foundry-rs/forge-std   # first time only
forge test -vv
```

You'll see `[PASS] test_drain` — including `credit after settle: 115792089237...` (the wrap) and a
ledger `vault 100 → 0`, `attacker 0 → 101 WETH` — and `[PASS] test_fixed` (the over-fee `settle`
reverts, the vault is untouched).

## Proven on Sepolia
The vault was deployed to the Sepolia testnet and hit with the same deposit → settle → redeem:

| Contract | Action | Tx | Result |
|---|---|---|---|
| Vulnerable vault `0xe93b…b3aa` | `redeem(101)` (after the underflow) | [`0x0c0b…cbc5`](https://sepolia.etherscan.io/tx/0x0c0be41fbb404d39a547028912a4fd1b4ad40b785c30c278a76b4745fff9cbc5) | ✅ Success — vault drained to 0 |
| Fixed vault | `settle(2)` (fee > credit) | [`0xd257…1fde`](https://sepolia.etherscan.io/tx/0xd2577f1509aa82b46b57850cd9438cf59212a2cbf4b14f0019f36e01d4ad1fde) | ❌ Fail — `execution reverted` (arithmetic underflow) |

## Key idea
- Since 0.8, over/underflow **reverts** for free; `unchecked` opts **out** to save gas. That trade is only safe on math that provably can't wrap.
- Underflow wraps a small balance to ~2^256 — the exact 2018-era overflow bug, back from the dead the moment the check is off.
- Never put attacker-controlled arithmetic (balances, credits, fees) inside `unchecked`. And keep one accounting source of truth, so two paths can never disagree the way Flooring's did.

## Sources
- Flooring Protocol exploit (Ethereum, June 2026, ~$900K): https://www.halborn.com/blog/post/explained-the-flooring-protocol-hack
- Solidity 0.8 checked arithmetic (over/underflow reverts): https://docs.soliditylang.org/en/latest/080-breaking-changes.html
- `unchecked` blocks: https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic
- DN404 standard: https://github.com/Vectorized/dn404
- Foundry: https://getfoundry.sh
