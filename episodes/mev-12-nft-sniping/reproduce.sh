#!/usr/bin/env bash
# mev12 — NFT mint & listing sniping. Reproduces the forge test AND the live Anvil mempool race.
# Requires: foundry (forge, cast, anvil). No network needed.
set -e
forge test -vv     # sniper (ordered first) wins token #0; user's mint reverts "sold out"; listing snipe too

echo "=== live Anvil mempool race: 5-gwei sniper is ordered ahead of a 1-gwei user who sent first ==="
anvil --port 8577 --order fees --silent & AN=$!; sleep 2
RPC=http://127.0.0.1:8577
DEP=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
USERK=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
SNIPERK=0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
SNIPER=0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
NFT=$(forge create src/RareMint.sol:RareMint --rpc-url $RPC --private-key $DEP --broadcast 2>/dev/null | grep "Deployed to:" | awk '{print $3}')
cast rpc --rpc-url $RPC evm_setAutomine false >/dev/null
# NOTE: explicit --gas-limit so cast skips gas-estimation (which would fail once one mint is pending)
UTX=$(cast send $NFT "mint()" --rpc-url $RPC --private-key $USERK   --legacy --gas-price 1000000000 --gas-limit 120000 --async 2>/dev/null)
STX=$(cast send $NFT "mint()" --rpc-url $RPC --private-key $SNIPERK --legacy --gas-price 5000000000 --gas-limit 120000 --async 2>/dev/null)
echo "pending: $(cast rpc --rpc-url $RPC txpool_status)"
cast rpc --rpc-url $RPC evm_mine >/dev/null
echo "block order (position 0 = highest gas = sniper):"
cast block latest --rpc-url $RPC --json | python3 -c "import sys,json;[print(' ',i,t) for i,t in enumerate(json.load(sys.stdin)['transactions'])]"
echo "ownerOf(#0) = $(cast call $NFT 'ownerOf(uint256)(address)' 0 --rpc-url $RPC)   (== sniper $SNIPER)"
echo "sniper tx status: $(cast receipt $STX status --rpc-url $RPC)"
echo "user   tx status: $(cast receipt $UTX status --rpc-url $RPC)   # reverted: sold out"
kill $AN
