# g08 — Anatomy of the $197M Euler Finance Hack (Rebuilt in Foundry)

Companion code for the 0xUnstuck video **"Anatomy of the $197M Euler Finance Hack"**.

On **2023-03-13**, an attacker drained **~$197M** from Euler Finance — a heavily audited lending
protocol — with **no stolen key and no broken crypto**. One function, `donateToReserves`, changed an
account's balances but **never re-checked its health**. So you could make **yourself** insolvent on
purpose, then have a second account **liquidate you** for the bonus — paid out of the pool.

## The bug (one missing line)
```solidity
function donateToReserves(uint256 amt) external {
    collateral[msg.sender] -= amt;
    reserves += amt;
    // MISSING: require(healthy(msg.sender), "unhealthy");   // ← the whole hack
}
```

## Run it — 3 acts
```bash
./reproduce.sh          # forge test -vv
```
- **Act 1 — honest:** a real 20% price drop makes Bob underwater → a fair liquidation works as intended.
- **Act 2 — attack:** no price move; the attacker self-sabotages via `donateToReserves`, self-liquidates,
  and ends with **more than it deposited** (start 1000 → end 1060, **+60**; pool drained by 60). Scale it
  up with a flash loan and repeat → $197M.
- **Act 3 — fix:** add `require(healthy(msg.sender))` to `donateToReserves` → the malicious donate
  **reverts** and the attack is impossible.

**Lesson:** re-check your core invariant (here: every account stays healthy) after **every** state change.
One un-checked path is enough — and "audited" does not mean immune.

## Files
- `src/EulerLite.sol` — the vulnerable pool (bug: `donateToReserves` skips the health check)
- `src/EulerLiteFixed.sol` — the one-line fix (BEFORE/AFTER marked in the source)
- `src/MockToken.sol` — minimal ERC20 used as the pool asset
- `test/Euler.t.sol` — the 3 acts (honest / attack / fix)

**Real attacker on-chain:** `0xb66cd966670d962C227B3EABA30a872DbFB995db` (Etherscan label: *Euler Finance
Exploiter*; involved in a flash-loan exploit on Euler; later returned the funds).
