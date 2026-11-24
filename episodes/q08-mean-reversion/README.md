# Mean Reversion Strategy, Backtested

[![Open in Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/nikshev/unstuck/blob/main/episodes/q08-mean-reversion/q08_mean_reversion.ipynb)

The z-score rule most tutorials teach (z over the last 20 candles, long below −2, short above +2, exit at the mean, no stop) on eleven Binance perpetuals, hourly candles, January 2021 – October 2026, with fees and funding, leverage 1. Two trades in three won, and 10,000 became 271. Then tuned the honest way: nine settings picked on 2021–2023, tested on 2024–2026 — the best in-sample setting made +19.5% a year, then −1.0% on the years it never saw.

- Notebook: `q08_mean_reversion.ipynb` — every cell has a title and one sentence above it; run it top to bottom.
- Backtester: [freqtrade](https://www.freqtrade.io) 2026.10, Binance USD-M futures, isolated margin. The tuning loop passes L and K to the strategy through environment variables.
- Data: [data.binance.vision](https://data.binance.vision), each monthly file checked against Binance's own SHA-256.
- Shared code: [`../quant-lib`](../quant-lib).
- Sharpe ratio: daily returns of the account value (marked to market) × √365, risk-free rate 0 (defined in the notebook, same four lines as q03).


Education, not financial advice. Backtested results do not predict future returns.
