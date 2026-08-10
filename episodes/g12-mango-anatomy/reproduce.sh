#!/usr/bin/env bash
# Reproduce the Mango Markets oracle-manipulation hack ($114M, Oct 2022) in 3 acts.
#   Act 1 — HONEST : a normal borrow within the collateral limit works.
#   Act 2 — ATTACK : pump the collateral token's spot price in a thin pool → the
#                    oracle reports the fake price → borrow far more than you deposited
#                    → drain the treasury.
#   Act 3 — FIX    : a median/TWAP oracle ignores the single-block pump, so the
#                    identical over-borrow reverts. Honest borrowing still works.
set -e
export PATH="$HOME/.foundry/bin:$PATH"
cd "$(dirname "$0")"
[ -d lib/forge-std ] || forge install foundry-rs/forge-std >/dev/null 2>&1 || true
echo "==> forge test -vv (all three acts)"
forge test -vv
cat <<'NOTE'

------------------------------------------------------------------------------
What you just saw:
  Act 1  alice borrows 800 against 1,000 of real collateral (price = 1)   [ok]
  Act 2  eve pumps spot 1 -> 100, collateral "worth" 100,000, borrows 80,000  [DRAIN]
  Act 3  same attack, median oracle still reads 1 -> borrow reverts 'undercollateralized'

The bug   : src/Oracles.sol       -> SpotOracle.price() = dex.spotPrice()  (manipulable)
The fix   : src/Oracles.sol       -> MedianOracle: median of hourly samples
Real hack : Mango Markets (Solana), 2022-10-11, ~$114M (Avraham Eisenberg)
------------------------------------------------------------------------------
NOTE
