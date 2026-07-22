#!/usr/bin/env bash
# =============================================================================
#  mev09 - JIT Liquidity (Uniswap v3) - full reproduce script
# =============================================================================
#  PREREQUISITES: foundry (forge+cast); a Sepolia RPC; a funded Sepolia key.
#    export RPC="https://your-sepolia-rpc-endpoint"
#    export PK="0xYOUR_FUNDED_SEPOLIA_PRIVATE_KEY"
#    ./reproduce.sh
#  Values are in wei (x10^18): 300000000000000000000 = 300 T1.
#  Fee on a 100,000 swap = 0.3% = 300 T1.
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")"
: "${RPC:?set RPC}"; : "${PK:?set PK}"
GP=$(( $(cast gas-price --rpc-url "$RPC") + 3000000000 ))
send(){ cast send "$1" "$2" ${3:-} --rpc-url "$RPC" --private-key "$PK" --legacy --gas-price "$GP" --json \
        | python3 -c "import sys,json;print(json.load(sys.stdin)['transactionHash'])"; }
addr(){ grep -oE "$1=0x[0-9a-fA-F]{40}" "$2" | head -1 | cut -d= -f2; }

echo "############ STEP 0 - deterministic local proof (Foundry) ############"
forge test -vv

echo; echo "############ ACT 1 - PASSIVE LP earns the whole fee ############"
forge script script/JitActsSepolia.s.sol:PassiveSepolia --rpc-url "$RPC" --private-key "$PK" --broadcast --legacy --gas-price "$GP" | tee /tmp/m1.log >/dev/null
POOL=$(addr POOL /tmp/m1.log); PASSIVE=$(addr PASSIVE /tmp/m1.log); TRADER=$(addr TRADER /tmp/m1.log)
echo "export POOL=$POOL"; echo "export PASSIVE=$PASSIVE"; echo "export TRADER=$TRADER"
echo "passive add tx: $(send "$PASSIVE" 'add(uint256)' 100000e18)"
echo "trader swap tx: $(send "$TRADER"  'swap(uint256)' 100000e18)"
echo "passive collect tx: $(send "$PASSIVE" 'collect()')"
echo "\$ cast call \$PASSIVE \"collected()(uint256)\" --rpc-url \$RPC"
cast call "$PASSIVE" "collected()(uint256)" --rpc-url "$RPC"    # 300e18 = the whole fee

echo; echo "############ ACT 2 - JIT sandwich (atomic) takes ~99% ############"
forge script script/JitActsSepolia.s.sol:JitSepolia --rpc-url "$RPC" --private-key "$PK" --broadcast --legacy --gas-price "$GP" | tee /tmp/m2.log >/dev/null
POOL=$(addr POOL /tmp/m2.log); PASSIVE=$(addr PASSIVE /tmp/m2.log); BUNDLE=$(addr BUNDLE /tmp/m2.log)
echo "export POOL=$POOL"; echo "export PASSIVE=$PASSIVE"; echo "export BUNDLE=$BUNDLE"
echo "passive add tx: $(send "$PASSIVE" 'add(uint256)' 100000e18)"
echo "JIT bundle tx (add+swap+collect+remove, ONE tx): $(send "$BUNDLE" 'run(uint256,uint256)' '9900000e18 100000e18')"
echo "\$ cast call \$BUNDLE \"jitFee()(uint256)\" --rpc-url \$RPC"
cast call "$BUNDLE" "jitFee()(uint256)" --rpc-url "$RPC"        # ~297e18 = 99% of the fee
echo "passive collect tx: $(send "$PASSIVE" 'collect()')"
echo "\$ cast call \$PASSIVE \"collected()(uint256)\" --rpc-url \$RPC"
cast call "$PASSIVE" "collected()(uint256)" --rpc-url "$RPC"    # ~3e18 = the 1% left

echo; echo "############ ACT 3 - TIME-WEIGHTED pool: same JIT earns ~0 ############"
forge script script/JitActsSepolia.s.sol:DefendedSepolia --rpc-url "$RPC" --private-key "$PK" --broadcast --legacy --gas-price "$GP" | tee /tmp/m3.log >/dev/null
POOL=$(addr POOL /tmp/m3.log); PASSIVE=$(addr PASSIVE /tmp/m3.log); BUNDLE=$(addr BUNDLE /tmp/m3.log)
echo "export POOL=$POOL"; echo "export PASSIVE=$PASSIVE"; echo "export BUNDLE=$BUNDLE"
echo "passive add tx: $(send "$PASSIVE" 'add(uint256)' 100000e18)"
echo "JIT bundle tx (atomic, 0 seconds in the pool): $(send "$BUNDLE" 'run(uint256,uint256)' '9900000e18 100000e18')"
echo "\$ cast call \$BUNDLE \"jitFee()(uint256)\" --rpc-url \$RPC"
cast call "$BUNDLE" "jitFee()(uint256)" --rpc-url "$RPC"        # ~0 = 0 liquidity-seconds
echo "passive collect tx: $(send "$PASSIVE" 'collect()')"
echo "\$ cast call \$PASSIVE \"collected()(uint256)\" --rpc-url \$RPC"
cast call "$PASSIVE" "collected()(uint256)" --rpc-url "$RPC"    # ~300e18 = passive keeps ~all
echo "############################  DONE  ############################"
