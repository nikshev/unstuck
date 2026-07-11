# DeFi #8 — Price Oracle Manipulation (UwU-Lend-class, ~$23M, 2024)

## 🎬 Watch

[![Watch on YouTube](https://img.youtube.com/vi/85hjBB08jgQ/maxresdefault.jpg)](https://youtu.be/85hjBB08jgQ)

▶️ **Watch: https://youtu.be/85hjBB08jgQ**


> **Illustrative reconstruction** for education — a minimal teaching model of the flaw,
> **not** the real bytecode. Do not deploy to mainnet.

📺 Video: **It Borrowed Against a Fake Price — $23M Oracle Manipulation**

## The bug ([`vulnerable.sol`](vulnerable.sol))
The lender values your collateral by asking an oracle for the price — and that oracle just returns
an AMM pool's **spot price** (its live reserve ratio). A spot price is a number **one big trade can
move**, so an attacker flash-borrows a fortune, swaps it into the pool to spike the collateral's
price ~100x, then deposits a little collateral and **borrows the entire pool** against the fake
value — reversing the swap to repay the flash loan. The price was a lie for exactly one transaction.

## The fix ([`fixed.sol`](fixed.sol))
Read price from a **manipulation-resistant oracle** — a decentralized feed (Chainlink) or a
**time-weighted average (TWAP)** that no single-block swap can move. Same lender, same borrow logic,
but now the swap can't change the reported price, so the over-borrow reverts.

## Run the proof
```bash
forge install foundry-rs/forge-std
forge test -vv
```
- `test_OLD_OracleManipulation_DrainsVault` — price 1,000 → **100,000** after one swap; pool **1,000,000 → 0**, attacker loot **1,000,000** (for 20 collateral)
- `test_FIXED_TrustedOracle_Reverts` — same attack, price stays 1,000, `drain()` **reverts**, pool intact

[`src/OracleDemo.sol`](src/OracleDemo.sol) is the click-to-run demo used in the video (Remix) and
deployed to Sepolia.

## Live on Sepolia (Etherscan-verified)
- Vulnerable (Attacker_OLD) — `0x282cC30E0E12cE8eF2C93059f6b9A17155adf5f2`
- Fixed (Attacker_NEW) — `0xC35A0abEC2B2eB25edDC873971647E445B5DcF20`
- 💀 Drain tx (Call Drain → Success) — `0x6ba2a9c40d2363fbb641f89c6bf2155962f7a8efc871fafc9a78e0a7768ceaf9`
- ✅ Fixed reverts (Call Drain → Fail) — `0x2954a93ee54d01c2e805c38932f34df52a0049a76beb9ebbaabe2c5a92ac49eb`

## The lesson
Never price collateral with a number a single trade can move. Real incident: **UwU Lend** (~$23M,
Ethereum, Jun 2024) — its sUSDE oracle read Curve pool reserves, manipulable with layered flash loans.

⚠️ Educational / not financial advice. Genericised — the lesson, not the names.
