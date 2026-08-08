#!/usr/bin/env bash
# g08 — Anatomy of the $197M Euler Finance hack (2023-03-13). A faithful Foundry reproduction of the
# MECHANISM: donateToReserves() lets you give away your OWN collateral with NO health re-check, so you
# can push yourself underwater on demand, then self-liquidate for the bonus — draining the pool.
# Requires foundry (forge).
set -e
cd "$(dirname "$0")"
[ -d lib/forge-std ] || forge install foundry-rs/forge-std --no-commit >/dev/null 2>&1 || true
forge test -vv
# ACT 1 honest : a genuine market drop makes Bob underwater -> a FAIR liquidation works
# ACT 2 attack : no market move; attacker donates collateral (no check) -> self-liquidates ->
#                starts 1000, ends 1060 (+60 profit), pool drained by 60  (scale up -> $197M)
# ACT 3 fix    : add require(healthy) to donateToReserves -> the malicious donate REVERTS "unhealthy"
