#!/usr/bin/env bash
# g06 — Your First Smart Contract (Solidity + Foundry). Writes a Counter, compiles it, tests it,
# then deploys it LIVE to a throwaway local chain and calls it — the exact loop shown in the video.
# Requires foundry (forge / cast / anvil). No funds, no keys of your own needed.
set -e
cd "$(dirname "$0")"
[ -d lib/forge-std ] || forge install foundry-rs/forge-std --no-commit >/dev/null 2>&1 || true

echo "== 1. compile =="
forge build --force

echo "== 2. test =="
forge test -vv

echo "== 3. live deploy + call on a local anvil =="
# chain-id 11155111 just makes block explorers label it "Sepolia" (ETH) instead of a generic chain.
anvil --silent --chain-id 11155111 --steps-tracing --order fifo & ANVIL=$!
trap 'kill $ANVIL 2>/dev/null' EXIT
sleep 3
RPC=http://localhost:8545
# Anvil's built-in, PUBLIC test key (account #0) — safe to publish, it only controls the local chain.
AK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

forge create src/Counter.sol:Counter --rpc-url "$RPC" --private-key "$AK" --broadcast
# On a fresh anvil, account #0's first deploy is always this deterministic address:
C=0x5FbDB2315678afecb367f032d93F642f64180aa3

cast send "$C" "increment()" --rpc-url "$RPC" --private-key "$AK"
echo "count = $(cast call "$C" 'count()(uint256)' --rpc-url "$RPC")   # -> 1"

# The SAME contract, deployed + verified on the real public Sepolia testnet:
#   0x7036A0920A58B033363E024bCBf76A87060eBebE
#   https://sepolia.etherscan.io/address/0x7036A0920A58B033363E024bCBf76A87060eBebE#code
