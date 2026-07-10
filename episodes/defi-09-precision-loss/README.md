# DeFi #9 — Precision Loss / Share Inflation (SonneFinance-class, ~$20M, 2024)

> **Illustrative reconstruction** for education — a minimal teaching model of the flaw,
> **not** the real bytecode. Do not deploy to mainnet.

📺 Video: **Your Deposit, Rounded Down to Nothing ($20M Precision Loss)**

## The bug ([`vulnerable.sol`](vulnerable.sol))
A share vault mints shares = `assets * totalShares / totalAssets`, and integer division **rounds
down**. On an almost-empty vault the attacker deposits **1 wei** (gets 1 share), then **donates** a
large amount straight in — raising `totalAssets` without minting shares, so 1 share is now "worth"
10,000. A victim's real deposit of 10,000 then mints `10000 * 1 / 10000 = 0` shares — the vault keeps
their money and gives them nothing. The attacker redeems their single share for the whole vault.

## The fix ([`fixed.sol`](fixed.sol))
`require(shares > 0)` — reject any deposit that would mint zero shares, so the victim's deposit
reverts instead of vanishing. In production, also seed **dead shares** on the first deposit or use a
**virtual shares+assets offset** (the OpenZeppelin ERC-4626 mitigation).

## Run the proof
```bash
forge install foundry-rs/forge-std
forge test -vv
```
- `test_OLD_ShareInflation_RobsVictim` — share price → 10,000; victim shares **0**; attacker loot **10,000**
- `test_FIXED_ZeroShareGuard_Reverts` — same attack, the victim's deposit **reverts** ("zero shares")

[`src/PrecisionDemo.sol`](src/PrecisionDemo.sol) is the click-to-run demo used in the video (Remix)
and deployed to Sepolia.

## Live on Sepolia (Etherscan-verified)
- Vulnerable (Attacker_OLD) — `0xD5768c8B9a8ACc3C220FC625120f55769b11E312`
- Fixed (Attacker_NEW) — `0x1A07c1BC4B94A3Ea0A7c709E3D57a762af79740E`
- 💀 Theft tx (Call Steal → Success) — `0x785a042ffce5c4bf154bd89f7abe73ee13d4ee6458972c71199aa8464beea4a9`
- ✅ Fixed reverts (victim deposit → Fail) — `0xd0432a52c43919d40d61b59977f660657e3f5e47f11197f8261c65028d84e992`

## The lesson
A deposit that mints zero shares is a robbery — reject it, and seed dead shares / use a virtual
offset on new vaults. Real incident: **Sonne Finance** (~$20M, Compound-fork empty-market donation
+ rounding, May 2024).

⚠️ Educational / not financial advice. Genericised — the lesson, not the names.
