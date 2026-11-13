# Backtesting With Leverage: Why It Lies

[![Open in Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/nikshev/unstuck/blob/main/episodes/q00-backtester-leverage/q00_backtester_leverage.ipynb)

One 10x long on Bitcoin, February 2020: four backtesters give four answers. We build a SHA-256-checked loader for raw Binance data, find why freqtrade and backtesting.py get the loss wrong, and teach freqtrade to liquidate — funding included.

- Notebook: `q00_backtester_leverage.ipynb` — every cell has a title and one sentence above it; run it top to bottom.
- Backtester: [freqtrade](https://www.freqtrade.io) 2026.10, Binance USD-M futures, isolated or cross margin as stated in the notebook.
- Data: [data.binance.vision](https://data.binance.vision), each monthly file checked against Binance's own SHA-256.
- Shared code: [`../quant-lib`](../quant-lib).

Education, not financial advice. Backtested results do not predict future returns.
