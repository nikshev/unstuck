#!/usr/bin/env bash
# Reproduce the Nomad Bridge "copy-paste" drain ($190M, Aug 2022) in three acts.
#   Act 1 — HONEST : a properly proven withdrawal pays out.
#   Act 2 — ATTACK : an UNPROVEN message drains the pool, then a copycat repeats it
#                    with a fresh address (the democratized, copy-paste hack).
#   Act 3 — FIX    : one guard (reject a zero root) makes the identical attack revert.
#
# The whole flaw is faithful to Nomad's real bug: a botched upgrade left the ZERO
# Merkle root marked "acceptable", and every unproven message defaults to that zero
# root — so the one check that guards every payout waved fakes straight through.
set -e
export PATH="$HOME/.foundry/bin:$PATH"
cd "$(dirname "$0")"

# fetch forge-std on a fresh clone
[ -d lib/forge-std ] || forge install foundry-rs/forge-std >/dev/null 2>&1 || true

echo "==> forge test -vv (all three acts)"
forge test -vv

cat <<'NOTE'

------------------------------------------------------------------------------
What you just saw:
  Act 1  alice withdrew 100,000 with a real proof     -> pool 1,000,000 -> 900,000
  Act 2  eve drained 600,000 with NO proof,           -> pool 1,000,000 -> 0
         bob COPIED it with his own address (400,000)
  Act 3  the same unproven drain reverts 'not proven'  (fixed bridge)

The bug   : src/NomadBridge.sol      -> constructor sets confirmAt[bytes32(0)] = 1
The fix   : src/NomadBridgeFixed.sol -> acceptableRoot() returns false for a zero root
Real hack : Nomad Bridge Exploiter 1  0x56D8B635A7C88Fd1104D23d632AF40c1C3Aac4e3
------------------------------------------------------------------------------
NOTE
