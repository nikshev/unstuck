# Grid Trading Bot, Backtested

[![Open in Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/nikshev/unstuck/blob/main/episodes/q06-grid-bot/q06_grid_bot.ipynb)

A spot grid bot on Bitcoin, a new bot on the first day of every month, February 2021 – October 2026: 69 bots, minute candles, 20 geometric grids, the range from the previous 30 days, a 0.1% fee. Grid profit was positive in 69 of 69 months, the account in only 47; reinvested, 10,000 became 6,218 while holding Bitcoin made 23,444.

- Notebook: `q06_grid_bot.ipynb` — every cell has a title and one sentence above it; run it top to bottom.
- No backtester this time: the order book is simulated in the notebook (freqtrade holds one position per coin, a grid holds up to 20 limit orders). Every bot checks its own books: cash never negative, total profit = grid profit + unrealized PnL, as on [Binance's help page](https://www.binance.com/en/support/faq/detail/688ff6ff08734848915de76a07b953dd).
- Data: [data.binance.vision](https://data.binance.vision) spot 1-minute klines, each monthly file checked against Binance's own SHA-256.
- Shared code: [`../quant-lib`](../quant-lib).
- Sharpe ratio: daily returns of the account value (marked to market) × √365, risk-free rate 0 (defined in the notebook, same four lines as q03).


Education, not financial advice. Backtested results do not predict future returns.
