# Turtle Trading Strategy, Backtested

[![Open in Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/nikshev/unstuck/blob/main/episodes/q01-turtle-trading/q01_turtle_trading.ipynb)

The complete Turtle rules from Curtis Faith's *The Original Turtle Trading Rules* (2003) — intraday breakouts, the System 1 filter and 55-day failsafe, N-based units, pyramiding, a stop per unit, unit limits, the notional account — on Bitcoin and Ethereum perpetual futures, 2020–2026, with fees, funding and liquidation.

- Notebook: `q01_turtle_trading.ipynb` — every cell has a title and one sentence above it; run it top to bottom.
- Backtester: [freqtrade](https://www.freqtrade.io) 2026.10, Binance USD-M futures, isolated or cross margin as stated in the notebook.
- Data: [data.binance.vision](https://data.binance.vision), each monthly file checked against Binance's own SHA-256.
- Shared code: [`../quant-lib`](../quant-lib).

Education, not financial advice. Backtested results do not predict future returns.
