# quant-lib — shared code of the "Quant Trading Strategies — Backtested on Crypto" series

Both files are generated from the notebooks, cell for cell, so the code here is exactly the code
explained on screen:

| file | built in | what |
|---|---|---|
| `binance_vision.py` | q00, code cells 2–10 | raw Binance futures data from data.binance.vision, every file checked against Binance's SHA-256, saved where freqtrade looks |
| `quant_report.py` | q01, sections 17–18 | freqtrade's verdict, and equity marked to market every hour (freqtrade's own "max drawdown" counts closed trades only) |

Education, not financial advice.
