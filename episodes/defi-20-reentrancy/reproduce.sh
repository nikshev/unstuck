#!/usr/bin/env bash
# Reproduce defi20 (classic reentrancy / The DAO) on Sepolia.
#   export RPC=<Sepolia RPC>;  export PK=<funded key>
set -euo pipefail
cd "$(dirname "$0")"
: "${RPC:?}"; : "${PK:?}"
GP=$(( $(cast gas-price --rpc-url "$RPC") + 3000000000 ))
DEP=$(cast wallet address --private-key "$PK")
tx(){ cast send "$@" --rpc-url "$RPC" --private-key "$PK" --legacy --gas-price "$GP" --json | python3 -c "import sys,json;print(json.load(sys.stdin)['transactionHash'])"; }
ethbal(){ cast balance "$1" --rpc-url "$RPC"; }

echo "############ ACT 1 HONEST: deposit then withdraw ############"
forge script script/HonestSepolia.s.sol:HonestSepolia --rpc-url "$RPC" --private-key "$PK" --broadcast --legacy --gas-price "$GP" >/tmp/d20h.log 2>&1
HV=$(grep -oE 'VAULT=0x[0-9a-fA-F]{40}' /tmp/d20h.log|head -1|cut -d= -f2)
echo "HONEST_VAULT=$HV  (holds 0.03 ETH)"; echo "vault balance:"; ethbal "$HV"
echo "HONEST_WITHDRAW_TX=$(tx "$HV" 'withdraw()')"
echo "vault after withdraw (expect 0):"; ethbal "$HV"

echo "############ ACT 2 ATTACK: re-enter withdraw() and drain ############"
forge script script/AttackSepolia.s.sol:AttackSepolia --rpc-url "$RPC" --private-key "$PK" --broadcast --legacy --gas-price "$GP" >/tmp/d20a.log 2>&1
AV=$(grep -oE 'VAULT=0x[0-9a-fA-F]{40}' /tmp/d20a.log|head -1|cut -d= -f2); ATK=$(grep -oE 'ATTACKER=0x[0-9a-fA-F]{40}' /tmp/d20a.log|head -1|cut -d= -f2)
echo "ATTACK_VAULT=$AV  ATTACKER=$ATK"
echo "vault before (expect 0.05):"; ethbal "$AV"
echo "ATTACK_TX=$(tx "$ATK" 'attack()' --value 0.01ether)"
echo "vault after (expect 0):"; ethbal "$AV"
echo "attacker contract after (expect ~0.06):"; ethbal "$ATK"

echo "############ ACT 3 FIXED: same attack, drain fails ############"
forge script script/FixedSepolia.s.sol:FixedSepolia --rpc-url "$RPC" --private-key "$PK" --broadcast --legacy --gas-price "$GP" >/tmp/d20f.log 2>&1
FV=$(grep -oE 'VAULT=0x[0-9a-fA-F]{40}' /tmp/d20f.log|head -1|cut -d= -f2); FATK=$(grep -oE 'ATTACKER=0x[0-9a-fA-F]{40}' /tmp/d20f.log|head -1|cut -d= -f2)
echo "FIXED_VAULT=$FV  ATTACKER=$FATK"
echo "vault before (expect 0.05):"; ethbal "$FV"
echo "FIXED_ATTACK_TX=$(tx "$FATK" 'attack()' --value 0.01ether)"
echo "vault after (expect 0.05 -- untouched):"; ethbal "$FV"
echo "attacker contract after (expect ~0.01):"; ethbal "$FATK"
echo "############ DONE ############"
