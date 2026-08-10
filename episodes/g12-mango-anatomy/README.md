# Anatomy of the $114M Mango Markets Hack (rebuilt in Foundry)

A faithful, teaching-sized reproduction of **oracle manipulation** — the attack that
drained **Mango Markets of ~$114M in October 2022**. There was no bug in the code: every
function ran correctly. The attacker just made one number lie — the price of a token.

## The bug in one sentence

The lending market valued collateral using a DEX **spot price** — the instantaneous
ratio of a pool's reserves. A single large swap moves that ratio, so the attacker pumped
the collateral token's price, borrowed against the inflated value, and never repaid.

```solidity
// src/Oracles.sol — the vulnerable oracle
contract SpotOracle is IOracle {
    function price() external view returns (uint256) {
        return dex.spotPrice();          // instantaneous — a single swap moves it
    }
}

// src/Oracles.sol — the fix: median of hourly samples (TWAP-style)
contract MedianOracle is IOracle {
    function poke() external { /* one sample per MIN_PERIOD */ }
    function price() external view returns (uint256) { /* median of the last N */ }
}
```

## Run it

```bash
./reproduce.sh          # or: forge test -vv
```

Expected:

```
[PASS] test_Act1_HonestBorrow            price 1 · collateral 1,000 · borrow 800
[PASS] test_Act2_OracleManipulationDrain pump 1->100 · collateral 100,000 · borrow 80,000 · pool -> 20,000
[PASS] test_Act3_MedianOracleBlocksIt    spot 100 but median 1 -> borrow reverts 'undercollateralized'
```

## Files

| File | Role |
|------|------|
| `src/MiniDEX.sol` | constant-product MNGO/USDC pool; its spot price is manipulable |
| `src/Oracles.sol` | `SpotOracle` (vulnerable) + `MedianOracle` (the fix) |
| `src/LendingPool.sol` | deposit collateral, borrow against `oracle.price()` |
| `src/MockToken.sol` | minimal ERC-20 that emits `Transfer` (token-flow shows on an explorer) |
| `test/Mango.t.sol` | the three acts |

## The real hack

- **Mango Markets** (Solana), 2022-10-11, **~$114M**. Attacker: Avraham Eisenberg, who
  publicly framed it as a "highly profitable trading strategy" — the courts disagreed.
- Faithful reproduction of the **mechanism** (spot-price collateral valuation -> pump ->
  over-borrow), simplified for teaching. Part of the *Crypto & Hacks, Explained* series.
