"""freqtrade results -> the figures we report, plus equity marked to market every hour.
Built line by line in episode q01 (sections 17 and 18)."""
from pathlib import Path
import pandas as pd
from binance_vision import DATA


from freqtrade.data.btanalysis import load_backtest_data, load_backtest_stats

def newest():
    return max(Path("user_data/backtest_results").glob("*.zip"),
               key=lambda p: p.stat().st_mtime)

MEANING = {
    "starting balance": "the deposit we start with",
    "final balance": "what the account is worth at the end",
    "CAGR": "compound annual growth rate: growth per year",
    "max drawdown": "deepest fall from a peak, closed trades only",
    "trades": "positions opened and closed",
    "long profit": "from longs (bets on a rise)",
    "short profit": "from shorts (bets on a fall)",
    "funding paid": "paid between longs and shorts every 8 h",
    "fees paid": "exchange fee, 0.05% of every order",
}

def shown(name, value):
    if name in ("CAGR", "max drawdown"):
        return f"{value:.1%}"                            # a share -> percent
    if name == "trades":
        return f"{value:.0f}"
    return f"{value:,.0f} USDT"

def verdict(name):
    s = load_backtest_stats(newest())["strategy"][name]   # freqtrade's summary
    t = load_backtest_data(newest())                      # every trade
    # fee = 0.05% of every order's value
    fees = sum(o["cost"] for orders in t["orders"] for o in orders) * 0.0005
    row = {"starting balance": s["starting_balance"],
           "final balance": s["final_balance"], "CAGR": s["cagr"],
           "max drawdown": s["max_drawdown_account"],
           "trades": s["total_trades"],
           "long profit": s["profit_total_long_abs"],
           "short profit": s["profit_total_short_abs"],
           "funding paid": t["funding_fees"].sum(), "fees paid": -fees}
    for name, value in row.items():                       # value + its meaning
        print(f"{name:<16}{shown(name, value):>13}  {MEANING[name]}")
    return row, t


def equity(trades, account=10_000, start=None):
    # hourly closes of every coin traded
    prices = pd.DataFrame({
        p: pd.read_feather(DATA / f"{p.split('/')[0]}_USDT_USDT-1h-futures"
                                  ".feather").set_index("date")["close"]
        for p in trades["pair"].unique()}).ffill()
    rows = []
    for pair, short, orders in zip(trades["pair"], trades["is_short"],
                                   trades["orders"]):
        for o in orders:
            sign = (1 if o["ft_is_entry"] else -1) * (-1 if short else 1)
            when = pd.to_datetime(o["order_filled_timestamp"], unit="ms",
                                  utc=True)
            rows.append((when, pair, o["amount"] * sign, o["safe_price"],
                         o["cost"]))
    fills = pd.DataFrame(rows,
                         columns=["time", "pair", "coins", "price", "cost"])
    # cash moved by each fill, minus its fee
    fills["cash"] = -fills["coins"] * fills["price"] - fills["cost"] * 0.0005
    value = 0
    for pair in prices:
        held = fills[fills["pair"] == pair].groupby("time")[["coins", "cash"]]
        held = held.sum().cumsum()                     # running totals
        held = held.reindex(prices.index.union(held.index)).ffill()
        held = held.fillna(0).reindex(prices.index)    # on every hour
        value = value + held["cash"] + held["coins"] * prices[pair]
    paid = trades.groupby("close_date")["funding_fees"].sum().cumsum()
    paid = paid.reindex(prices.index.union(paid.index)).ffill()
    paid = paid.fillna(0).reindex(prices.index)        # booked at each close
    return (account + value + paid).loc[start:]

def drawdown(curve):
    # the deepest fall from the highest point reached so far
    return (1 - curve / curve.cummax()).max()
