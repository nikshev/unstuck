# Statistical Arbitrage on Crypto, Backtested

[![Open in Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/nikshev/unstuck/blob/main/episodes/q05-statistical-arbitrage/q05_statistical_arbitrage.ipynb)

Pairs trading with the rules of Gatev, Goetzmann & Rouwenhorst (2006) — 12-month formation, smallest sum of squared deviations, open at 2 standard deviations, close when the prices cross — on ten Binance perpetuals, February 2021 – October 2026, with fees, funding and liquidation; plus the cointegration version most tutorials teach and pairs picked with hindsight. 10,000 became 8,847; Sharpe 0.07 against about 2.0 for the paper's pairs on US stocks.

- Notebook: `q05_statistical_arbitrage.ipynb` — every cell has a title and one sentence above it; run it top to bottom.
- Backtester: [freqtrade](https://www.freqtrade.io) 2026.10, Binance USD-M futures, isolated or cross margin as stated in the notebook.
- Data: [data.binance.vision](https://data.binance.vision), each monthly file checked against Binance's own SHA-256.
- Shared code: [`../quant-lib`](../quant-lib).
- Sharpe ratio: daily returns of the account value (marked to market) × √365, risk-free rate 0 (defined in the notebook, same four lines as q03).


Education, not financial advice. Backtested results do not predict future returns.
