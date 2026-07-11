#!/usr/bin/env bash
# Local MEV lab: forked Anvil (:8555) + Otterscan explorer (:5100).
# usage: mev-anvil.sh {up|down|status} [order=fees] [forkBlock]
# requires: foundry (anvil/cast), docker, and $ETH_RPC_URL set to a mainnet RPC.
set -uo pipefail
PORT=8555; RPC="http://127.0.0.1:$PORT"
case "${1:-status}" in
  up)
    : "${ETH_RPC_URL:?set ETH_RPC_URL to a mainnet RPC}"
    ORDER="${2:-fees}"; BLK="${3:-}"
    pkill -f "anvil --port $PORT" 2>/dev/null; sleep 1
    A="--port $PORT --host 127.0.0.1 --fork-url $ETH_RPC_URL --order $ORDER"
    [ -n "$BLK" ] && A="$A --fork-block-number $BLK"
    nohup anvil $A > anvil.log 2>&1 &
    sleep 9; echo "anvil block: $(cast block-number --rpc-url $RPC)"
    docker ps --filter name=otterscan --filter status=running -q | grep -q . || \
      docker run -d --name otterscan -p 5100:80 -e ERIGON_URL="$RPC" otterscan/otterscan:latest >/dev/null
    echo "otterscan: http://localhost:5100"
    ;;
  down) pkill -f "anvil --port $PORT" 2>/dev/null; docker rm -f otterscan 2>/dev/null; echo stopped ;;
  status) echo "block: $(cast block-number --rpc-url $RPC)"; docker ps --filter name=otterscan --format '{{.Status}}' ;;
esac
