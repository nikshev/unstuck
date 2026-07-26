# defi22 — zkLend Accumulator Rounding ($9.5M, Feb 2025)

A lending market mints zToken receipts scaled by a `lendingAccumulator` (an exchange rate). `withdraw`
computes the zTokens to **burn** as `floor(amount * RAY / accumulator)` — rounded **down**. Once the
accumulator is inflated on a near-empty market (via flash-loan interest), a withdrawal smaller than one
zToken's worth burns **zero** zTokens, so the attacker withdraws the asset for free and drains the pool.
This drained zkLend of **$9.5M** despite two audits. (Original was Starknet/Cairo; this is a faithful
Solidity/Foundry reproduction of the mechanism.)

**Fix:** round the burned zTokens **UP** (ceil) — rounding must always favour the protocol. `mint` rounds
a deposit's credit down; `withdraw` rounds a withdrawal's cost up. Now a free withdrawal reverts.

## Reproduce
```
./reproduce.sh
```
- `forge test -vv` — ACT 1 honest (100→100), ACT 2 drain (pool 100→0, attacker burns 0 zTokens), ACT 3 fix (free withdrawal reverts).
- Live Anvil: deploy + deposit 100 + inflate the accumulator, then the attacker `withdraw(19e18)` — pool 100→81, attacker zTokens stay 0, attacker wstETH 0→19.

## Verified live on Sepolia (Etherscan)
- MARKET `0xf52866e37be6d4F2074dE33999487a0B82f5afF7` · asset (Lab wstETH) `0x20528cbc1A99b5Ec077b90138add3c20d535a99a`
- deposit `0x03556dd093f73e84f1238f66d195a56878a0a11a41e40886d3a3ddc297318007`
- inflate `0xcedf3016308dcd7b63bc6d01a49ab1e6938e2dfd46158fc0cec719c840e52a49`
- **the free withdrawal (money tx)** `0x43ebb9f26c08f0523f3b02dd605f58a5a31849b8c8ecd8f15ac4c43e6e2add1b`
  → Etherscan "ERC-20 Tokens Transferred": MARKET → attacker **19 wstETH**, Value 0 ETH, and the attacker's
  zToken balance is **0 before and 0 after**. Open it: https://sepolia.etherscan.io/tx/0x43ebb9f26c08f0523f3b02dd605f58a5a31849b8c8ecd8f15ac4c43e6e2add1b

Files: `Underlying.sol` (ERC-20), `Market.sol` (vulnerable, floor), `MarketFixed.sol` (fixed, ceil), `Zklend.t.sol` (3-act test).
