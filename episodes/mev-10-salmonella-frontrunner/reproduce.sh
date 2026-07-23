#!/usr/bin/env bash
# Reproduce mev10 (Salmonella honeypot) on Sepolia.
#   export RPC=<Sepolia RPC>;  export PK=<funded key>   # the deployer is the honeypot OWNER
set -euo pipefail
cd "$(dirname "$0")"
: "${RPC:?}"; : "${PK:?}"
GP=$(( $(cast gas-price --rpc-url "$RPC") + 3000000000 ))
BOB=$(cast wallet address --private-key 0x0000000000000000000000000000000000000000000000000000000000000002)
SINK=$(cast wallet address --private-key 0x0000000000000000000000000000000000000000000000000000000000000003)
tx(){ cast send "$@" --rpc-url "$RPC" --private-key "$PK" --legacy --gas-price "$GP" --json | python3 -c "import sys,json;print(json.load(sys.stdin)['transactionHash'])"; }
bal(){ cast call "$1" "balanceOf(address)(uint256)" "$2" --rpc-url "$RPC"; }

echo "############ DEPLOY ############"
forge script script/SalmonellaSepolia.s.sol:SalmonellaSepolia --rpc-url "$RPC" --private-key "$PK" --broadcast --legacy --gas-price "$GP" >/tmp/m10.log 2>&1
SALM=$(grep -oE 'SALM=0x[0-9a-fA-F]{40}' /tmp/m10.log|head -1|cut -d= -f2)
BOT=$(grep -oE 'BOT=0x[0-9a-fA-F]{40}' /tmp/m10.log|head -1|cut -d= -f2)
SAFE=$(grep -oE 'SAFE=0x[0-9a-fA-F]{40}' /tmp/m10.log|head -1|cut -d= -f2)
echo "SALM=$SALM"; echo "BOT=$BOT"; echo "SAFE=$SAFE"; echo "BOB=$BOB"; echo "SINK=$SINK"

echo "############ ACT 1 HONEST: the OWNER moves 1000 -> 1000 arrives ############"
echo "HONEST_TX=$(tx "$SALM" 'transfer(address,uint256)' "$BOB" 1000e18)"
echo "bob balance (expect 1000):"; bal "$SALM" "$BOB"

echo "############ ACT 2 TRAP: the BOT (front-runner) moves 1000 -> event 1000, only 10 arrives ############"
echo "TRAP_TX=$(tx "$BOT" 'run(address,address,uint256)' "$SALM" "$SINK" 1000e18)"
echo "sink REAL balance (expect 10 -- the event LIED):"; bal "$SALM" "$SINK"

echo "############ ACT 3 FIX: SafeReceiver verifies the delta -> reverts on the short transfer ############"
# bot approves the safe receiver, then pull reverts
echo "bot approves the safe receiver: $(tx "$BOT" 'approveSpender(address,address)' "$SALM" "$SAFE")"
set +e
cast send "$SAFE" 'pull(address,address,uint256)' "$SALM" "$BOT" 1000e18 --rpc-url "$RPC" --private-key "$PK" --legacy --gas-price "$GP" 2>/tmp/m10rev.txt
echo "pull result:"; tail -3 /tmp/m10rev.txt
set -e
echo "############ DONE ############"
