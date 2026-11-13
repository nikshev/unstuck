# Time Series Momentum, Backtested

[![Open in Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/nikshev/unstuck/blob/main/episodes/q02-time-series-momentum/q02_time_series_momentum.ipynb)

Moskowitz, Ooi and Pedersen's time-series momentum (Journal of Financial Economics, 2012) on every coin that had a Binance perpetual in January 2020 — long and short, with fees and funding, and the delisted coin the backtester silently drops.

- Notebook: `q02_time_series_momentum.ipynb` — every cell has a title and one sentence above it; run it top to bottom.
- Backtester: [freqtrade](https://www.freqtrade.io) 2026.10, Binance USD-M futures, isolated or cross margin as stated in the notebook.
- Data: [data.binance.vision](https://data.binance.vision), each monthly file checked against Binance's own SHA-256.
- Shared code: [`../quant-lib`](../quant-lib).

Education, not financial advice. Backtested results do not predict future returns.
