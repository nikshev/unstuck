# D2 · Hyperliquid Whale Tracker — Dune SQL

Queries from **"Hyperliquid Whale Tracker: Follow the Money Into Hyperliquid"** (Dune Dashboards ep 2).
Hyperliquid deposits = **USDC transfers on Arbitrum to the Hyperliquid Bridge2 contract**
(`0x2Df1c51E09aECF9cacB7bc98cB1742757f163dF7`), so we read `tokens_arbitrum.transfers`.

> Note: Hyperliquid's per-trader **P&L is Enterprise-gated on Dune** — the free data is the bridge
> flow (deposits/withdrawals), which is what these queries use. It's a real whale/funding signal.

| File | Tile | What it does |
|------|------|--------------|
| `01_net_inflows.sql` | bar chart | daily **net** inflow (money in − out), `sum(CASE WHEN to=bridge THEN amount ELSE -amount END)` |
| `02_top_depositors.sql` | bar chart | top depositors ("whales") by USDC bridged in (30d) |
| `03_biggest_deposits.sql` | table (results) | biggest **single** deposits with timestamp + address (whale moves), 30d |
| `03b_biggest_deposits_bar.sql` | bar chart | same data, 2-column (label + value) shape for the dashboard bar tile |

The published dashboard is **three bar-chart tiles**: daily net inflows, top depositors, and biggest
deposits. Leaderboards render as **bars, not raw result tables** — a categorical bar needs a text
label column + one numeric column, so the leaderboard/biggest-deposit queries are shaped that way for
the chart (the 3-column `03` stays as the human-readable results table shown in the video).

Live dashboard: **https://dune.com/nikshev81/hyperliquid-whale-tracker**
Swap the bridge/token addresses to track flows into any protocol.
