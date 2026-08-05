#!/usr/bin/env bash
# g02 — Anatomy of the $625M Ronin Bridge hack (2022-03-23). A faithful Foundry
# reproduction of the MECHANISM: a 5-of-9 validator multisig bridge. There was no
# contract bug — the attacker stole 5 of 9 validator keys, so the forged withdrawal
# is a perfectly VALID signature. Requires foundry (forge). No mainnet/RPC needed.
set -e
cd "$(dirname "$0")"
[ -d lib/forge-std ] || forge install foundry-rs/forge-std --no-commit >/dev/null 2>&1 || true
forge test -vv
# ACT 1 honest : 5 real validators approve a user  -> bridge 100 -> 90, user +10
# ACT 2 attack : attacker holds 5 STOLEN keys       -> bridge 100 -> 0,  attacker +100
# ACT 3 fix    : same forged withdrawal, but time-locked; guardian pauses -> bridge stays 100
