# D2b · Add Filters to Your Dune Dashboard — Whale Size + Timeframe

Parameterized version of the D2 Hyperliquid Whale Tracker queries. Two **free** Dune query
**parameters** turn the dashboard into a filterable tool:

- `{{days}}` — timeframe / look-back window (e.g. 7, 30, 90)
- `{{min_usdc}}` — minimum deposit size (the "whale floor")

Use the **same parameter names in every query** — Dune then links them into **one shared filter per
name** on the dashboard (two dropdowns control all three tiles). Change a filter → hit **Run** →
confirm **"Run N queries"** → the whole board recomputes from live chain data.

| File | Tile | Params |
|------|------|--------|
| `01_net_inflows_params.sql` | daily net inflow (bar) | `{{days}}`, `{{min_usdc}}` |
| `02_top_depositors_params.sql` | top depositors (bar) | `{{days}}`, `{{min_usdc}}` |
| `03_biggest_deposits_params.sql` | biggest single deposits (bar) | `{{days}}`, `{{min_usdc}}` |

Filtered dashboard: **https://dune.com/nikshev81/hyperliquid-whale-tracker-filtered**
Try `min_usdc = 1000000`, `days = 7` — net inflows flip **negative** (whales pulling out).

> Note: automatic scheduled refresh is a paid Dune feature. On the free plan, a **Run** re-reads live
> on-chain data (each tile stamps "Now" / "Updated X ago"). Swap the addresses to filter flows into
> any protocol.
