# 0xUnstuck

[![YouTube](https://img.shields.io/badge/YouTube-%400xunstuck-red?logo=youtube&logoColor=white)](https://youtube.com/@0xunstuck)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> web3 security + Rust + the dev errors nobody documents — every video, runnable.

Code companions for the [0xUnstuck](https://youtube.com/@0xunstuck) YouTube channel. Each episode is
short and self-contained: clone it, run it, see the point. DeFi exploits and MEV are reconstructed
and reproduced on **private local forks** — nothing here targets real users or funds.

**4 playlists:**
- 🔓 **DeFi Exploits, Explained** — real hacks reconstructed in Foundry, exploited, and verified on-chain.
- ⚡ **MEV Explained** — MEV from its origins, reproduced live on a local Anvil fork + Foundry + Otterscan.
- 🦀 **Rust Coding Challenges** — classic problems in Rust, brute force → optimal, every step explained.
- 🛠️ **Dev Errors, Fixed** — the errors everyone hits, explained properly and fixed.

---

## 🔓 DeFi Exploits, Explained
Real incidents, genericised and reconstructed in Foundry, then exploited and verified on-chain (Sepolia).

| Exploit | Loss | Code | Video |
|---|---|---|---|
| Access-control / RFQ drain (TrustedVolumes-class) | ~$5.87M | [defi-01-trusted-volumes](episodes/defi-01-trusted-volumes) | [▶](https://youtu.be/Is5Dr2S1zTQ) |
| Arbitrary external call (SwapNet-class) | ~$13.4M | [defi-06-arbitrary-call](episodes/defi-06-arbitrary-call) | [▶](https://youtu.be/vHK8u_fkUXU) |
| Reentrancy (Stars-Arena-class) | ~$3M | [defi-07-reentrancy](episodes/defi-07-reentrancy) | [▶](https://youtu.be/CLNUqUDjee0) |
| Price-oracle manipulation (UwU-Lend-class) | ~$23M | [defi-08-oracle-manipulation](episodes/defi-08-oracle-manipulation) | [▶](https://youtu.be/85hjBB08jgQ) |
| Precision loss / share inflation (Sonne-class) | ~$20M | [defi-09-precision-loss](episodes/defi-09-precision-loss) | [▶](https://youtu.be/WfZWq8lFJa8) |
| Signature replay (KiloEx-class) | ~$8.4M | [defi-10-signature-replay](episodes/defi-10-signature-replay) | 🔜 |

## ⚡ MEV Explained
MEV taught from the very beginning, every episode reproduced live on a local Ethereum fork (Anvil),
with Foundry, and shown in a real explorer (Otterscan). More episodes rolling out — arbitrage,
sandwiches, liquidations, JIT, and the MEV supply chain.

| Episode | Topic | Code | Video |
|---|---|---|---|
| 1 | What Is MEV? — Flash Boys 2.0 & Priority Gas Auctions | [mev-01-what-is-mev](episodes/mev-01-what-is-mev) | 🔜 |
| 2 | DEX Arbitrage — Uniswap v2 vs SushiSwap (buy cheap, sell dear, 1 tx) | [mev-02-dex-arbitrage](episodes/mev-02-dex-arbitrage) | 🔜 |

## 🦀 Rust Coding Challenges

| Problem | Code | Video |
|---|---|---|
| Two Sum — O(n) hash map | [03-two-sum](episodes/03-two-sum) | [▶](https://youtu.be/2f_GHO8M8-E) |
| Merge Sort — O(n log n) | [04-merge-sort](episodes/04-merge-sort) | [▶](https://youtu.be/b31-cU29WOA) |
| FizzBuzz — done right | [05-fizzbuzz](episodes/05-fizzbuzz) | [▶](https://youtu.be/VgRy_An3ZWo) |
| Valid Parentheses — the stack | [07-valid-parentheses](episodes/07-valid-parentheses) | [▶](https://youtu.be/o-szOloQtZI) |
| Binary Search — bug-free template | [08-binary-search](episodes/08-binary-search) | [▶](https://youtu.be/Zd6tO3-tEtk) |
| Contains Duplicate — HashSet | [09-contains-duplicate](episodes/09-contains-duplicate) | [▶](https://youtu.be/Fo1mwIyduHA) |
| Reverse a Linked List — in-place | [11-reverse-linked-list](episodes/11-reverse-linked-list) | [▶](https://youtu.be/UOf6XrXZoZM) |
| Quicksort + the O(n²) trap | [12-quicksort](episodes/12-quicksort) | [▶](https://youtu.be/Vf-9XRJFoa8) |
| Valid Anagram — O(n) char counts | [13-valid-anagram](episodes/13-valid-anagram) | [▶](https://youtu.be/3wufMwFiT0A) |
| Climbing Stairs — DP from scratch | [15-climbing-stairs](episodes/15-climbing-stairs) | [▶](https://youtu.be/0AZo5iaRpFs) |
| Bubble Sort — the honest verdict | [16-bubble-sort](episodes/16-bubble-sort) | [▶](https://youtu.be/HQacr4_NUQI) |
| Group Anagrams — canonical key | [17-group-anagrams](episodes/17-group-anagrams) | [▶](https://youtu.be/Kqfi3_vYpFA) |
| Maximum Subarray — Kadane's O(n) | [19-maximum-subarray](episodes/19-maximum-subarray) | [▶](https://youtu.be/2CmFgGeBC1k) |
| Insertion Sort — why libraries use it | [20-insertion-sort](episodes/20-insertion-sort) | [▶](https://youtu.be/86Q6Y9dmiEQ) |
| Number of Islands — DFS flood fill | [21-number-of-islands](episodes/21-number-of-islands) | [▶](https://youtu.be/Pqvb4RNYR4Y) |
| Longest Substring w/o Repeats — sliding window | [23-longest-substring](episodes/23-longest-substring) | [▶](https://youtu.be/Z6j-TY6LyMk) |
| Coin Change — DP min coins | [25-coin-change](episodes/25-coin-change) | 🔜 |

## 🛠️ Dev Errors, Fixed

| Error | Stack | Code | Video |
|---|---|---|---|
| "Blockhash not found" | Solana | [01-blockhash-not-found](episodes/01-blockhash-not-found) | [▶](https://youtu.be/x73cikwFZTU) |
| "TokenAccountNotFoundError" | Solana | [02-token-account-not-found](episodes/02-token-account-not-found) | [▶](https://youtu.be/Y71iJbjOCG8) |
| Fix a Git merge conflict | git | [06-git-merge-conflict](episodes/06-git-merge-conflict) | [▶](https://youtu.be/GrjrgR89FzY) |
| "Cannot read properties of undefined" | JS | [10-cannot-read-undefined](episodes/10-cannot-read-undefined) | [▶](https://youtu.be/4KeWfekcK4k) |
| "Port 3000 already in use" (EADDRINUSE) | Node | [14-port-in-use](episodes/14-port-in-use) | [▶](https://youtu.be/fQMfFAEKiSs) |
| Fix the CORS error (the right way) | Web | [18-cors](episodes/18-cors) | [▶](https://youtu.be/3vpaV1tyQ3s) |
| "X is not a function" | JS | [22-x-is-not-a-function](episodes/22-x-is-not-a-function) | [▶](https://youtu.be/jgceaLXm5Rw) |
| npm ERESOLVE peer-dependency errors | Node | [24-npm-eresolve](episodes/24-npm-eresolve) | [▶](https://youtu.be/vBKKuD3gdQA) |
| Fix Python KeyError | Python | [26-python-keyerror](episodes/26-python-keyerror) | 🔜 |

---

## Running an episode
- **Rust** (needs [rustup](https://rustup.rs)): `cd episodes/<ep> && cargo run --release`
- **Node / JS** (needs [Node](https://nodejs.org)): `cd episodes/<ep> && node <file>.js` (some need `npm install` first)
- **DeFi** (needs [Foundry](https://getfoundry.sh)): `cd episodes/defi-<ep> && forge test -vvv`
- **MEV** (needs Foundry + Docker): see the episode README — set `ETH_RPC_URL`, then `./mev-anvil.sh up` and `./pga_demo.sh` (explorer at http://localhost:5100).

Each episode folder has its own `README.md` with the video, the walk-through, and how to run it.

## ⚠️ Disclaimer
The DeFi and MEV episodes are **educational reconstructions**. They run on private local forks
(Anvil) or a public testnet (Sepolia) — never against real users, funds, or live protocols. Don't
use any of it to harm others.

## Support
- **SOL / USDC (Solana):** `3bQPvjmVr2hXdZuzByxmoo3kwkjUwTdnerUUDYUweF2K`
- **ETH / USDC (Ethereum):** `0xf96102f5f500f1E51E3A1e9B576977fB2EaC83E5`
- **USDT (Tron):** `TXA9qxr9yZjV3yEPiN9gGYzV6agfCUbizj`
- **Ko-fi:** https://ko-fi.com/0xunstuck

## License
MIT — see [LICENSE](LICENSE).
