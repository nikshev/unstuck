# DeFi Exploits — Ep 17: Uninitialized Proxy Hijack

## 🎬 Watch

🔴 **New episode** — [Subscribe](https://www.youtube.com/channel/UC32d5uV5MEC1oMqVaVbQPNA?sub_confirmation=1) to catch it when it drops.

An upgradeable contract keeps its **logic** in one contract and its **storage + funds** in a **proxy** in
front of it. The proxy's owner is meant to be set **once**, by `initialize()`, at deploy time. This one has
two bugs: `initialize()` has **no one-shot guard** (it can be called again and again) and it is **never
called atomically** at deploy — so the live proxy sits there with `owner == address(0)`, up for grabs.
An attacker calls `initialize(attacker)`, becomes the owner for **free**, and the "owner-only" `withdraw()`
now hands them the whole vault. Here an honest user's **100 ETH** walks straight out the door.

## The idea in one test

`test/UninitProxy.t.sol` deploys the `Vault` logic behind a minimal `ERC1967Proxy`, never initializes it,
then runs both the attack and the fix:

- **`test_hijack`** — the proxy goes live uninitialized (`owner == 0`) → an honest user deposits **100 ETH**
  → the attacker calls the wide-open `initialize(attacker)` and becomes owner for nothing → the owner-only
  `withdraw()` drains the vault → **attacker +100 ETH, vault empty**.
- **`test_fixed`** — `VaultFixed` adds a one-shot `initializer` guard and is initialized **atomically** by
  the deployer at deploy time. A second `initialize(attacker)` now **reverts** (`already initialized`), the
  attacker's `withdraw()` reverts (`not owner`), and the funds stay put.

> The real fix is the guard every upgradeable contract needs: OpenZeppelin's `initializer` / `reinitializer`
> modifiers, plus `_disableInitializers()` in the logic constructor. Claim the owner slot in the *same* flow
> that deploys the proxy, and there is never an open window to front-run.

## Run it yourself

Requires [Foundry](https://getfoundry.sh).

```bash
forge install foundry-rs/forge-std   # first time only
forge test -vv
```

You'll see `[PASS] test_hijack` (attacker drains **100 ETH** from a `0`-owner proxy) and `[PASS] test_fixed`
(the one-shot guard + atomic init make the second `initialize()` revert).

## Proven on Sepolia (public Etherscan)

The on-chain capstone was driven with `cast` as **two real transactions** against an uninitialized proxy,
through a Chainstack node:

1. **Seize** — [`0x2460…c9949`](https://sepolia.etherscan.io/tx/0x2460ac31397f234f6571b06e80f55340e084a58cda7cc794cb2b7649874c9949) — `initialize(attacker)` claims the empty `owner` slot; no permission needed.
2. **Drain** — [`0xe003…ad78e`](https://sepolia.etherscan.io/tx/0xe003fe7de28aeaf4e92d2db3472b5c05f38de110f045fd496add4111848ad78e) — the fresh "owner" calls `withdraw()` and empties the vault (**0.02 ETH**).

Proxy `0x1c1ecce7a68dcb53afe299dc4e6ef7dceae5db85` · attacker `0x4FB4299076A0bE795457427B70920297E742E6FC`.

## ⚠️ Educational only

Everything runs on a local chain / testnet — no real users or funds. Don't use any of this to harm others.
