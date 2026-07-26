#!/usr/bin/env bash
# mev13 — private orderflow beats the sandwich. Requires foundry (forge, cast, anvil).
set -e
forge test -vv   # PUBLIC victim gets 9,976 TOKEN (sandwiched) vs PRIVATE victim 14,244 (mined alone)

echo "=== live on Anvil: same 5-WETH buy, public (sandwiched) vs private (alone) ==="
anvil --port 8601 --silent & AN=$!; sleep 2
RPC=http://127.0.0.1:8601; PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
dep(){ forge create src/Pool.sol:Pool --rpc-url $RPC --private-key $PK --broadcast --constructor-args 100000000000000000000 300000000000000000000000 2>/dev/null | grep "Deployed to:" | awk '{print $3}'; }
P1=$(dep); cast send $P1 "buy(uint256)" 20000000000000000000 --rpc-url $RPC --private-key $PK >/dev/null   # front-run
echo "PUBLIC  victim TOKEN out: $(cast call $P1 'buy(uint256)(uint256)' 5000000000000000000 --rpc-url $RPC)"
P2=$(dep)
echo "PRIVATE victim TOKEN out: $(cast call $P2 'buy(uint256)(uint256)' 5000000000000000000 --rpc-url $RPC)"
kill $AN
