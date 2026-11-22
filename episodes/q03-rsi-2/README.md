# RSI 2 Strategy, Backtested

[![Open in Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/nikshev/unstuck/blob/main/episodes/q03-rsi-2/q03_rsi_2.ipynb)

Larry Connors' RSI(2) mean-reversion rules, word for word (long above the 200-day SMA when RSI(2) drops below 5, short below it when RSI(2) rises above 95, exit on the 5-day SMA, no stop loss), on ten Binance perpetuals, 2021–2026, with fees and funding. Longs made money on every coin, shorts lost on every coin; long only: 14,992 from 10,000, Sharpe 0.61 against 0.68 for holding.

- Notebook: `q03_rsi_2.ipynb` — every cell has a title and one sentence above it; run it top to bottom.
- Backtester: [freqtrade](https://www.freqtrade.io) 2026.10, Binance USD-M futures, isolated or cross margin as stated in the notebook.
- Data: [data.binance.vision](https://data.binance.vision), each monthly file checked against Binance's own SHA-256.
- Shared code: [`../quant-lib`](../quant-lib).
- Sharpe ratio: daily returns of the account value (marked to market) × √365, risk-free rate 0 (defined in the notebook, same four lines as q03).


Education, not financial advice. Backtested results do not predict future returns.
