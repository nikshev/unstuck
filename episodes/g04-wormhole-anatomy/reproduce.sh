#!/usr/bin/env bash
# g04 — Anatomy of the $325M Wormhole hack (2022-02-02). A faithful Foundry reproduction of the
# MECHANISM: a bridge that mints wrapped tokens when it sees enough "guardian" signatures — but it
# verifies them against a guardian set the CALLER supplies, not its own. Requires foundry (forge).
set -e
cd "$(dirname "$0")"
[ -d lib/forge-std ] || forge install foundry-rs/forge-std --no-commit >/dev/null 2>&1 || true
forge test -vv
# ACT 1 honest : real guardians attest a deposit  -> mint 10 to the user
# ACT 2 attack : attacker signs with their OWN keys, passes them as "guardians" -> mint 120,000 wETH from nothing
# ACT 3 fix    : verify against the contract's OWN stored guardians -> forged sigs revert "not a guardian", mint 0
