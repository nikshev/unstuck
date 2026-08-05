# Anatomy of the $625M Ronin Bridge Hack — rebuilt in Foundry

March 2022: **$625,000,000** was withdrawn from the Ronin bridge, unnoticed for six days — with **no
bug in the contract**. Withdrawals needed **5 of 9 validator signatures**; the entire security was the
keys. Attackers (Lazarus Group) phished Sky Mavis for 4 keys and got a 5th from a leftover Axie DAO
permission that was never revoked. Five of nine — enough to sign a valid withdrawal to themselves.

This is a faithful reproduction of the **mechanism** (a minimal 5-of-9 multisig bridge), in three acts.

## Files
- `Bridge.sol` — the vulnerable-by-trust bridge: `withdraw()` releases funds given ≥ threshold valid
  validator signatures. The code is correct; a stolen-key signature is indistinguishable from a real one.
- `BridgeFixed.sol` — the fix: large withdrawals are **time-locked** (queued, not instant) and a
  **guardian** can **pause** during the delay window.
- `Ronin.t.sol` — three acts, using `vm.sign` to produce real validator signatures.

## Run
```bash
./reproduce.sh          # forge test -vv
```
Expected:
- **Act 1 (honest):** 5 real validators approve a user → bridge `100 → 90`, user `+10`.
- **Act 2 (attack):** attacker holds 5 stolen keys → forged withdrawal → bridge `100 → 0`, attacker `+100`.
- **Act 3 (fix):** same forged (valid) withdrawal → queued; guardian pauses → `execute()` reverts
  `bridge paused` → bridge stays `100`, attacker `0`.

## The real hack, on-chain
Ronin Bridge Exploiter: [`0x098B716B8Aaf21512996dC57EB0615e2383E2f96`](https://etherscan.io/address/0x098B716B8Aaf21512996dC57EB0615e2383E2f96)
(Etherscan labels: Ronin Bridge Exploiter · Exploit · OFAC-Sanctioned · Blocked). ~$625M = 173,600 ETH + 25.5M USDC.

## The lesson
The contract wasn't broken — the trust around it was. Decentralize validators (no single party holds a
majority), revoke old permissions, and time-lock + monitor the money that matters.

> Educational reproduction. No real funds or users involved.
