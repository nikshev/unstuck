"""Read on-chain data with web3.py — connect, read balances, decode events.
Public RPC on screen (safe). Run:  python read_chain.py"""
import os
from web3 import Web3

# 1) Connect to an Ethereum node over HTTP (a public RPC — no key needed)
RPC = os.environ.get("ETH_RPC", "https://ethereum-rpc.publicnode.com")
w3 = Web3(Web3.HTTPProvider(RPC))
print("connected:", w3.is_connected())
print("latest block:", w3.eth.block_number)

# 2) Read an account's ETH balance (returned in wei, convert to ether)
vitalik = Web3.to_checksum_address("0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045")
wei = w3.eth.get_balance(vitalik)
print(f"vitalik.eth: {w3.from_wei(wei, 'ether'):.4f} ETH")

# 3) Call an ERC-20 contract: symbol, decimals, balanceOf
USDC = Web3.to_checksum_address("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48")
ERC20_ABI = [
    {"name": "symbol",    "inputs": [], "outputs": [{"type": "string"}], "stateMutability": "view", "type": "function"},
    {"name": "decimals",  "inputs": [], "outputs": [{"type": "uint8"}],  "stateMutability": "view", "type": "function"},
    {"name": "balanceOf", "inputs": [{"name": "a", "type": "address"}], "outputs": [{"type": "uint256"}], "stateMutability": "view", "type": "function"},
]
usdc = w3.eth.contract(address=USDC, abi=ERC20_ABI)
sym = usdc.functions.symbol().call()
dec = usdc.functions.decimals().call()
bal = usdc.functions.balanceOf(vitalik).call()
print(f"vitalik.eth: {bal / 10**dec:,.2f} {sym}")

# 4) Read + decode raw logs: USDC Transfer events in the latest block
topic = w3.keccak(text="Transfer(address,address,uint256)").to_0x_hex()
logs = w3.eth.get_logs({"fromBlock": "latest", "address": USDC, "topics": [topic]})
print(f"USDC transfers in the latest block: {len(logs)}")
for lg in logs[:3]:
    frm = "0x" + lg["topics"][1].hex()[-40:]
    to  = "0x" + lg["topics"][2].hex()[-40:]
    amt = int(lg["data"].hex(), 16) / 10**dec
    print(f"   {frm[:10]}… -> {to[:10]}…  {amt:,.2f} {sym}")
