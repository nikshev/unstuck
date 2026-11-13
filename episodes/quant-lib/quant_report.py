"""freqtrade results -> the figures we report, plus equity marked to market every hour.
Built line by line in episode q01 (sections 17 and 18)."""
from pathlib import Path
import pandas as pd
from binance_vision import DATA


from freqtrade.data.btanalysis import load_backtest_data, load_backtest_stats

def newest():
    return max(Path("user_data/backtest_results").glob("*.zip"), key=lambda p: p.stat().st_mtime)

def verdict(name):
    s = load_backtest_stats(newest())["strategy"][name]
    t = load_backtest_data(newest())
    fees = sum(o["cost"] for orders in t["orders"] for o in orders) * 0.0005
    row = {"final balance": s["final_balance"], "CAGR": s["cagr"],
           "max drawdown": s["max_drawdown_account"], "trades": s["total_trades"],
           "long profit": s["profit_total_long_abs"], "short profit": s["profit_total_short_abs"],
           "funding paid": t["funding_fees"].sum(), "fees paid": -fees}
    print(pd.Series(row).round(3).to_string())
    return row, t


def equity(trades, account=10_000, start=None):
    prices = pd.DataFrame({p: pd.read_feather(DATA / f"{p.split('/')[0]}_USDT_USDT-1h-futures.feather")
                           .set_index("date")["close"] for p in trades["pair"].unique()}).ffill()
    fills = pd.DataFrame([(pd.to_datetime(o["order_filled_timestamp"], unit="ms", utc=True), pair,
                           o["amount"] * (1 if o["ft_is_entry"] else -1) * (-1 if short else 1),
                           o["safe_price"], o["cost"])
                          for pair, short, orders in zip(trades["pair"], trades["is_short"], trades["orders"])
                          for o in orders], columns=["time", "pair", "coins", "price", "cost"])
    fills["cash"] = -fills["coins"] * fills["price"] - fills["cost"] * 0.0005
    value = 0
    for pair in prices:
        held = fills[fills["pair"] == pair].groupby("time")[["coins", "cash"]].sum().cumsum()
        held = held.reindex(prices.index.union(held.index)).ffill().fillna(0).reindex(prices.index)
        value = value + held["cash"] + held["coins"] * prices[pair]
    paid = trades.groupby("close_date")["funding_fees"].sum().cumsum()
    paid = paid.reindex(prices.index.union(paid.index)).ffill().fillna(0).reindex(prices.index)
    return (account + value + paid).loc[start:]

def drawdown(curve):
    return (1 - curve / curve.cummax()).max()
