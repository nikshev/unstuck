# DeFi Exploits, Explained — Ep 11: Flash-Loan Governance Takeover

## 🎬 Watch

[![Watch on YouTube](https://img.youtube.com/vi/BS1twmo7BKk/maxresdefault.jpg)](https://youtu.be/BS1twmo7BKk)

▶️ **Watch: https://youtu.be/BS1twmo7BKk**

One of the wildest DeFi hacks ever (Beanstalk Farms, ~$182M, April 2022): an attacker borrows a
supermajority of a protocol's governance token with a **flash loan**, uses those borrowed votes to
pass their own malicious proposal, drains the treasury to themselves, and repays the loan — **all in
one transaction**. No stolen keys; they just followed the rules of a broken voting system.

## The idea in one test
`test/FlashGov.t.sol` builds a minimal version:
- `GovToken` — an ERC-20 with a naive, uncollateralised `flashLoan`.
- `Governance` (VULNERABLE) — holds the treasury; `vote()` counts your **current** token balance.
- `Attacker` — one `pwn()` call: flash-borrow the majority → propose → vote → execute (drain) → repay.
- `GovernanceFixed` — the one-line fix: a **timelock** so propose and execute can't share a block.

`test_drain` proves the drain (`drained to attacker (ETH): 100`); `test_fixed_blocksIt` proves the
timelock reverts the same attack.

## Run it yourself
Requires [Foundry](https://getfoundry.sh).

```bash
forge install foundry-rs/forge-std   # first time only
forge test -vvv
```

You'll see `[PASS] test_drain` (treasury emptied) and `[PASS] test_fixed_blocksIt` (attack reverts).

## Proven on Sepolia
Both governances were deployed to the Sepolia testnet and hit with the **same** attack:

| Governance | Contract | Attack tx | Result |
|---|---|---|---|
| Vulnerable | `0xA39B10bed8222C9f9950953A38E894669e445bA7` | [`0x0900…0cac9`](https://sepolia.etherscan.io/tx/0x09008bca8ba11460037bc721bbbc4a64e88de6330a1a20481b12bf95faa0cac9) | ✅ Success — treasury drained |
| Fixed (timelock) | `0x47756F046cBaE38aA8571399d22789640E289635` | [`0xb3c5…40e7ea`](https://sepolia.etherscan.io/tx/0xb3c5b8e249ecb1e8175dd34b1c899f633761a30afe2693b462a256fef540e7ea) | ❌ Fail — `timelock: wait a block` |

## Key idea
- The root cause is **not** the flash loan — it's counting votes by an **instantaneous balance**.
- Fix: **snapshot** voting power at proposal time, or add a **timelock** between propose and execute,
  so one-block, flash-borrowed power is worthless.
- If control can be rented by the second, it was never really control.

## Sources
- Beanstalk post-mortem (Apr 2022): https://bean.money/blog/beanstalk-governance-exploit
- Rekt — Beanstalk: https://rekt.news/beanstalk-rekt/
- OpenZeppelin Governor (snapshot voting): https://docs.openzeppelin.com/contracts/governance
- Foundry: https://getfoundry.sh

---
*Educational. Everything runs on a private local chain / testnet — no real users or funds. Part of the [0xUnstuck](https://github.com/nikshev/unstuck) DeFi Exploits series.*
