# DeFi Exploits — Ep 15: The First-Depositor Inflation Attack

## 🎬 Watch

🔔 [Subscribe on YouTube](https://www.youtube.com/channel/UC32d5uV5MEC1oMqVaVbQPNA?sub_confirmation=1) — a DeFi exploit rebuilt **and fixed** every episode.

The very first depositor into a share vault can set a trap for everyone after them. Deposit **1 wei**
(now you own the whole vault — one share), then **donate** a pile of tokens straight into the vault with a
raw transfer, so one share is suddenly worth ~100 WETH. The next depositor's real deposit divides down to
**zero shares** — and the attacker redeems their single share for the whole pot.

## The idea in one test

`test/Inflation.t.sol` builds a minimal ERC-4626-style share vault and runs the attack on it:

- **`test_inflation`** — attacker deposits 1 wei, donates 100 WETH, victim deposits 100 WETH →
  `100 * 1 / 100` rounds **down to 0 shares**, attacker redeems their 1 share → **200 WETH**.
  Profit: **100 WETH** — the victim's entire deposit, lifted clean.
- **`test_fixed`** — the vault uses **virtual shares/assets** (the OpenZeppelin ERC-4626 offset). The
  victim now mints ~**1,999 shares** and redeems ~**99.97 WETH**. The donation attack no longer pays.

> Integer division rounds **down**. Spike the share price high enough and a real deposit rounds to nothing.
> The fix: pretend the vault always holds a little phantom liquidity, so a donation can't move the price.

## Run it yourself

Requires [Foundry](https://getfoundry.sh).

```bash
forge install foundry-rs/forge-std   # first time only
forge test -vv
```

You'll see `[PASS] test_inflation` (victim **0 shares**, attacker **+100 WETH**) and `[PASS] test_fixed`
(victim ~1,999 shares, redeems ~99.97 WETH — the attack defeated).

## Proven on Sepolia (public Etherscan)

`script/InflationSepolia.s.sol` deploys the vulnerable vault (plus a `MockWETH`) and runs the attack as
**three real transactions** on the Sepolia testnet, through a Chainstack node:

1. **Donate** — [`0x8ef0…4bb75`](https://sepolia.etherscan.io/tx/0x8ef0955fec4bd75c25031a2b4e63f34d4634776c4da4b56999bcf6f29144bb75) — attacker sends 100 WETH straight into the vault (one share now ≈ 100 WETH).
2. **Victim** — [`0x8644…0e41b`](https://sepolia.etherscan.io/tx/0x8644b19f788e6a7b4b722d048ff5bc1e2b9eeb315d9fbfac569c4ebc5910e41b) — deposits 100 WETH and mints **0 shares**.
3. **Redeem** — [`0x0ec9…875a7e`](https://sepolia.etherscan.io/tx/0x0ec926c6107867adfe80977cb9c91100e795329320c7438ecbffb38358875a7e) — the attacker's one share pulls out **200 WETH**.

## ⚠️ Educational only

Everything runs on a local fork / testnet — no real users or funds. Don't use any of this to harm others.
