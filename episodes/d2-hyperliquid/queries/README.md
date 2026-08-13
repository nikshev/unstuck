# D2 · Hyperliquid Whale Tracker — Dune SQL

Queries from **"Hyperliquid Whale Tracker: Follow the Money Into Hyperliquid"** (Dune Dashboards ep 2).
Hyperliquid deposits = **USDC transfers on Arbitrum to the Hyperliquid Bridge2 contract**
(`0x2Df1c51E09aECF9cacB7bc98cB1742757f163dF7`), so we read `tokens_arbitrum.transfers`.

> Note: Hyperliquid's per-trader **P&L is Enterprise-gated on Dune** — the free data is the bridge
> flow (deposits/withdrawals), which is what these queries use. It's a real whale/funding signal.

| File | Tile | What it does |
|------|------|--------------|
| `01_net_inflows.sql` | bar chart | daily **net** inflow (money in − out), `sum(CASE WHEN to=bridge THEN amount ELSE -amount END)` |
| `02_top_depositors.sql` | table | top depositors ("whales") by USDC bridged in (30d) |
| `03_biggest_deposits.sql` | table | biggest **single** deposits (whale moves), 30d |

Live dashboard: **https://dune.com/nikshev81/hyperliquid-whale-tracker**
Swap the bridge/token addresses to track flows into any protocol.
