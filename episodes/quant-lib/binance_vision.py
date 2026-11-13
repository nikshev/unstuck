"""Raw Binance futures data from data.binance.vision, checked against Binance's SHA-256,
saved where freqtrade looks. Built line by line in episode q00 (code cells 2-10)."""


import hashlib, io, json, re, zipfile, urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import warnings
import pandas as pd
import matplotlib.pyplot as plt
warnings.filterwarnings("ignore", category=UserWarning)


BASE = "https://data.binance.vision/data/futures/um/monthly"
LIST = "https://s3-ap-northeast-1.amazonaws.com/data.binance.vision"

def fetch(url, tries=4):
    for attempt in range(tries):
        try:
            with urllib.request.urlopen(url, timeout=60) as r:
                return r.read()
        except OSError:
            if attempt == tries - 1:
                raise


def verified_zip(url):
    blob = fetch(url)
    expected = fetch(url + ".CHECKSUM").decode().split()[0]
    actual = hashlib.sha256(blob).hexdigest()
    if actual != expected:
        raise ValueError(f"checksum mismatch: {url}")
    return zipfile.ZipFile(io.BytesIO(blob))


def read_csv(z):
    df = pd.read_csv(z.open(z.namelist()[0]), header=None)
    return df[pd.to_numeric(df[0], errors="coerce").notna()].astype(float)


def months(start, end):
    return [p.strftime("%Y-%m") for p in pd.period_range(start, end, freq="M")]

def archived(prefix):
    xml = fetch(f"{LIST}?prefix=data/futures/um/monthly/{prefix}/&delimiter=/").decode()
    return set(re.findall(r"<Key>[^<]*/([^/<]+\.zip)</Key>", xml))


def download_all(urls):
    with ThreadPoolExecutor(max_workers=16) as pool:
        return list(pool.map(lambda u: read_csv(verified_zip(u)), urls))


def klines(symbol, interval, start, end, kind="klines"):
    have = archived(f"{kind}/{symbol}/{interval}")
    names = [f"{symbol}-{interval}-{m}.zip" for m in months(start, end)]
    parts = download_all([f"{BASE}/{kind}/{symbol}/{interval}/{n}" for n in names if n in have])
    df = pd.concat([p.iloc[:, :6] for p in parts], ignore_index=True)
    df.columns = ["date", "open", "high", "low", "close", "volume"]
    df["date"] = pd.to_datetime(df["date"], unit="ms", utc=True)
    return df.drop_duplicates("date").sort_values("date").reset_index(drop=True)


def funding(symbol, start, end):
    have = archived(f"fundingRate/{symbol}")
    names = [f"{symbol}-fundingRate-{m}.zip" for m in months(start, end)]
    parts = download_all([f"{BASE}/fundingRate/{symbol}/{n}" for n in names if n in have])
    df = pd.concat([p.iloc[:, [0, 2]] for p in parts], ignore_index=True)
    df.columns = ["date", "funding_rate"]
    df["date"] = pd.to_datetime(df["date"], unit="ms", utc=True).dt.round("h")
    return df.drop_duplicates("date").sort_values("date").reset_index(drop=True)


DATA = Path("user_data/data/binance/futures")

def save_for_freqtrade(symbol, timeframe, start, end):
    DATA.mkdir(parents=True, exist_ok=True)
    pair = symbol.replace("USDT", "_USDT_USDT")
    klines(symbol, timeframe, start, end).to_feather(DATA / f"{pair}-{timeframe}-futures.feather")
    klines(symbol, "1h", start, end).to_feather(DATA / f"{pair}-1h-futures.feather")
    klines(symbol, "1h", start, end, "markPriceKlines").to_feather(DATA / f"{pair}-1h-mark.feather")
    funding(symbol, start, end).to_feather(DATA / f"{pair}-1h-funding_rate.feather")
