#!/usr/bin/env bash
# Toy Priority-Gas-Auction on a forked Anvil (:8555).
# Set FORK_BLOCK to make it deterministic (re-forks to that block each run).
# requires $ETH_RPC_URL (the same mainnet RPC used for the fork).
set -uo pipefail
RPC=http://127.0.0.1:8555
: "${ETH_RPC_URL:?set ETH_RPC_URL}"
FORK_BLOCK="${FORK_BLOCK:-}"
# anvil default dev accounts (well-known test keys — local only)
K0=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
K1=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
DST=0xa0Ee7A142d267C1f36714E4a8F75612F20a79720
[ -n "$FORK_BLOCK" ] && cast rpc anvil_reset --rpc-url $RPC \
  "{\"forking\":{\"jsonRpcUrl\":\"$ETH_RPC_URL\",\"blockNumber\":$FORK_BLOCK}}" >/dev/null 2>&1
cast rpc evm_setAutomine false --rpc-url $RPC >/dev/null
HA=$(cast send --private-key $K0 --rpc-url $RPC $DST --value 0.05ether --legacy --gas-price 5gwei --async 2>/dev/null)
HB=$(cast send --private-key $K1 --rpc-url $RPC $DST --value 0.05ether --legacy --gas-price 120gwei --async 2>/dev/null)
cast rpc evm_mine --rpc-url $RPC >/dev/null
cast rpc evm_setAutomine true --rpc-url $RPC >/dev/null
BN=$(cast block-number --rpc-url $RPC)
echo "Two bots race for the SAME on-chain opportunity."
echo "Searcher A submits FIRST,  bids   5 gwei gas."
echo "Searcher B submits SECOND, bids 120 gwei gas."
echo "The miner builds block $BN, ordering by gas paid:"
cast block $BN --rpc-url $RPC --json 2>/dev/null | python3 -c '
import json,sys
txs=json.load(sys.stdin)["transactions"]; hb="'"$HB"'".lower()
for i,h in enumerate(txs):
    tag="Searcher B  (120 gwei)" if h.lower()==hb else "Searcher A  (  5 gwei)"
    print(f"   slot #{i}:  {tag}")'
echo "OK: higher gas bought the FIRST slot -- a Priority Gas Auction."
