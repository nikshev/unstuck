#!/usr/bin/env bash
# Read on-chain data with web3.py: connect, ETH balance, ERC-20 call, decode Transfer logs.
set -e
cd "$(dirname "$0")"
python3 -m pip install -q --break-system-packages web3 2>/dev/null || pip install -q web3 || true
python3 read_chain.py
