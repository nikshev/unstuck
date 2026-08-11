# Read On-Chain Data with Python (web3.py)

A tiny, beginner-friendly tour of reading Ethereum with **web3.py** — no API key, a free public RPC.

## What it does
1. **Connect** to a node over HTTP (`Web3(HTTPProvider(rpc))`) and print the latest block.
2. **ETH balance** — `eth.get_balance(addr)` → convert wei → ether with `from_wei`.
3. **ERC-20 call** — build a contract from an address + minimal ABI, call `symbol` / `decimals` / `balanceOf`.
4. **Decode raw logs** — hash the `Transfer(address,address,uint256)` signature, `eth.get_logs` for the
   latest block, and decode `topics` (from/to) + `data` (amount) by hand.

## Run
```bash
pip install web3
python3 read_chain.py     # or ./reproduce.sh
```

The RPC is read from `ETH_RPC` (defaults to a public node — `ethereum-rpc.publicnode.com`). Point it at
your own node to go faster:
```bash
ETH_RPC=https://your-node python3 read_chain.py
```

## Example output
```
connected: True
latest block: 25730092
vitalik.eth: 6.6340 ETH
vitalik.eth: 37.19 USDC
USDC transfers in the latest block: 18
   0x1d6d074c… -> 0x0e0da253…  600,000.00 USDC
   ...
```

Part of the *Crypto & Hacks, Explained* series — from reading the chain to building bots.
