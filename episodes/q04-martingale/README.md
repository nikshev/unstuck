# Martingale Trading, Backtested

[![Open in Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/nikshev/unstuck/blob/main/episodes/q04-martingale/q04_martingale.ipynb)

A martingale ("DCA with a volume scale of 2") bot on Bitcoin perpetual futures, hourly, January 2020 – October 2026: without leverage, then 3x and 5x with real isolated liquidation. It won 1,191 of 1,193 trades and still ended at 14,850 while holding Bitcoin made 108,097.

The strategy file also carries a one-line fix for a freqtrade quirk: after every averaging-down fill freqtrade re-applies the stop's percentage to the new average price, so a liquidation stop given relative to the current price lands about 3% too high (`ref = trade.open_rate if after_fill else current_rate`).

- Notebook: `q04_martingale.ipynb` — every cell has a title and one sentence above it; run it top to bottom.
- Backtester: [freqtrade](https://www.freqtrade.io) 2026.10, Binance USD-M futures, isolated or cross margin as stated in the notebook.
- Data: [data.binance.vision](https://data.binance.vision), each monthly file checked against Binance's own SHA-256.
- Shared code: [`../quant-lib`](../quant-lib).
- Sharpe ratio: daily returns of the account value (marked to market) × √365, risk-free rate 0 (defined in the notebook, same four lines as q03).


Education, not financial advice. Backtested results do not predict future returns.
