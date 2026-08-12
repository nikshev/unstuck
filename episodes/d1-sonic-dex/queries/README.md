# D1 · Sonic DEX Volume Dashboard — Dune SQL

The queries from the video **"Build a DEX Volume Dashboard on Dune (Sonic)"** — first episode of the
*Dune Dashboards* series. All read the curated **`dex.trades`** table (one decoded row per DEX swap),
filtered to `blockchain = 'sonic'`. Paste into a free Dune account and hit Run.

| File | Tile | What it does |
|------|------|--------------|
| `01_daily_volume.sql` | bar chart | daily DEX volume + trade count (last 30d) — `date_trunc('day', block_time)` + `sum(amount_usd)` |
| `02_top_pools.sql` | table | top pools by volume (last 7d) — `least()/greatest()` merges both trade directions into one pair |
| `03_top_tokens.sql` | table | top tokens traded by volume (last 7d) |

**Make it interactive:** replace the `30` in `interval '30' day` with a Dune parameter `{{days}}` →
Dune renders a dropdown so viewers pick 7 / 30 / 90 days and the whole dashboard updates.

Swap `'sonic'` for any chain (`'base'`, `'polygon'`, …) and it works unchanged.
