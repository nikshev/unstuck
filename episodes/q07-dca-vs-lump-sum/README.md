# DCA vs Lump Sum, Backtested

[![Open in Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/nikshev/unstuck/blob/main/episodes/q07-dca-vs-lump-sum/q07_dca_vs_lump_sum.ipynb)

All the money into Bitcoin at once (lump sum), or in equal parts over the following months (DCA, dollar-cost averaging)? Both tested on every start day from August 2017 (2,998 of them), with the method of [Vanguard's 2023 study](https://corporate.vanguard.com/content/dam/corp/research/pdf/cost_averaging_invest_now_or_temporarily_hold_your_cash.pdf): wealth after one year, waiting cash earns nothing. The lump sum won on 61.5% of start days against DCA over 12 months and on 55% against Vanguard's 3-month plan (they found 68% on stocks); on the nine years that share no day, DCA won 5 to 4; DCA cut the worst year from −82% to −59%. Then the same on Ethereum.

- Notebook: `q07_dca_vs_lump_sum.ipynb` — every cell has a title and one sentence above it; run it top to bottom.
- No backtester: a buying schedule is not a trading rule, a few lines of numpy say it exactly.
- Data: [data.binance.vision](https://data.binance.vision) spot daily klines, each monthly file checked against Binance's own SHA-256.
- Shared code: [`../quant-lib`](../quant-lib).
- Sharpe ratio: daily returns of the account value × √365, risk-free rate 0, one per start day (defined in the notebook, same four lines as q03).


Education, not financial advice. Backtested results do not predict future returns.
