#!/usr/bin/env bash
# =============================================================================
#  defi18 - Flash-Loan Reward Manipulation - full reproduce script
# =============================================================================
#  Everything shown in the video is produced by this script. Each act:
#    1. deploys fresh contracts to Sepolia
#    2. reads the BEFORE state with `cast call`   (real, on-chain)
#    3. runs the action with `cast send`          (a real, clickable tx)
#    4. reads the AFTER state with `cast call`    (real, on-chain)
#
#  PREREQUISITES
#    - foundry (forge + cast):  curl -L https://foundry.paradigm.xyz | bash && foundryup
#    - a Sepolia RPC endpoint     (e.g. Chainstack / Alchemy / Infura)
#    - a funded Sepolia account   (needs a little test-ETH for gas)
#
#  RUN
#    export RPC="https://your-sepolia-rpc-endpoint"
#    export PK="0xYOUR_FUNDED_SEPOLIA_PRIVATE_KEY"
#    ./reproduce.sh
#
#  Values printed by `cast` are in wei (x10^18). e.g. 100000000000000000000000 = 100,000 tokens.
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")"
: "${RPC:?set RPC to your Sepolia RPC url}"
: "${PK:?set PK to a funded Sepolia private key}"

# a small gas bump over the current base fee, so txs confirm promptly
GP=$(( $(cast gas-price --rpc-url "$RPC") + 3000000000 ))
send(){ cast send "$1" "$2" ${3:-} --rpc-url "$RPC" --private-key "$PK" --legacy --gas-price "$GP" --json \
        | python3 -c "import sys,json;print(json.load(sys.stdin)['transactionHash'])"; }
addr(){ grep -oE "$1=0x[0-9a-fA-F]{40}" "$2" | head -1 | cut -d= -f2; }

echo "############################################################"
echo "# STEP 0 - the deterministic local proof (Foundry tests)"
echo "############################################################"
forge test -vv     # test_honest, test_drain, test_fixed - full balance-by-balance logs

echo
echo "############################################################"
echo "# ACT 1 - the HONEST flow (fair, proportional rewards)"
echo "############################################################"
forge script script/HonestSepolia.s.sol:HonestSepolia \
  --rpc-url "$RPC" --private-key "$PK" --broadcast --legacy --gas-price "$GP" | tee /tmp/h.log >/dev/null
POOL=$(addr POOL /tmp/h.log); RWD=$(addr RWD /tmp/h.log)
ALICE=$(addr ALICE /tmp/h.log); BOB=$(addr BOB /tmp/h.log)
echo "export POOL=$POOL"; echo "export RWD=$RWD"; echo "export ALICE=$ALICE"; echo "export BOB=$BOB"
echo "--- BEFORE: the reward pot ---"
echo "\$ cast call \$POOL \"rewardReserve()(uint256)\" --rpc-url \$RPC"
cast call "$POOL" "rewardReserve()(uint256)" --rpc-url "$RPC"     # 100000...e18 = 100,000 RWD
echo "--- Alice stakes 1,000, Bob stakes 1,000 ---"
echo "alice stake tx: $(send "$ALICE" 'stake(uint256)' 1000e18)"
echo "bob   stake tx: $(send "$BOB"   'stake(uint256)' 1000e18)"
echo "\$ cast call \$POOL \"totalStaked()(uint256)\" --rpc-url \$RPC"
cast call "$POOL" "totalStaked()(uint256)" --rpc-url "$RPC"       # 2000e18 -> Alice owns HALF
echo "--- Alice claims her fair share ---"
echo "alice claim tx: $(send "$ALICE" 'claim()')"
echo "\$ cast call \$RWD \"balanceOf(address)(uint256)\" \$ALICE --rpc-url \$RPC"
cast call "$RWD" "balanceOf(address)(uint256)" "$ALICE" --rpc-url "$RPC"   # 50000e18 = fair 50%

echo
echo "############################################################"
echo "# ACT 2 - the ATTACK (flash-loan reward manipulation)"
echo "############################################################"
forge script script/RewardSepolia.s.sol:RewardSepolia \
  --rpc-url "$RPC" --private-key "$PK" --broadcast --legacy --gas-price "$GP" | tee /tmp/a.log >/dev/null
POOL=$(addr POOL /tmp/a.log); RWD=$(addr RWD /tmp/a.log); ATTACKER=$(addr ATTACKER /tmp/a.log)
FLASH=$(grep -oE 'FLASH=[0-9]+' /tmp/a.log | head -1 | cut -d= -f2)
echo "export POOL=$POOL"; echo "export RWD=$RWD"; echo "export ATTACKER=$ATTACKER"
echo "--- BEFORE ---"
echo "\$ cast call \$POOL \"rewardReserve()(uint256)\" --rpc-url \$RPC";        cast call "$POOL" "rewardReserve()(uint256)" --rpc-url "$RPC"
echo "\$ cast call \$RWD \"balanceOf(address)(uint256)\" \$ATTACKER --rpc-url \$RPC"; cast call "$RWD" "balanceOf(address)(uint256)" "$ATTACKER" --rpc-url "$RPC"
echo "--- the exploit: borrow -> stake -> claim -> unstake -> repay, ALL in one atomic tx ---"
echo "attack tx: $(send "$ATTACKER" 'attack(uint256)' "$FLASH")"
echo "--- AFTER ---"
echo "\$ cast call \$POOL \"rewardReserve()(uint256)\" --rpc-url \$RPC";        cast call "$POOL" "rewardReserve()(uint256)" --rpc-url "$RPC"   # ~10 left: drained
echo "\$ cast call \$RWD \"balanceOf(address)(uint256)\" \$ATTACKER --rpc-url \$RPC"; cast call "$RWD" "balanceOf(address)(uint256)" "$ATTACKER" --rpc-url "$RPC"  # ~99,990 stolen

echo
echo "############################################################"
echo "# ACT 3 - the FIX (time-weighted rewards) - same attack earns 0"
echo "############################################################"
forge script script/FixedSepolia.s.sol:FixedSepolia \
  --rpc-url "$RPC" --private-key "$PK" --broadcast --legacy --gas-price "$GP" | tee /tmp/f.log >/dev/null
POOL=$(addr POOL /tmp/f.log); RWD=$(addr RWD /tmp/f.log); ATTACKER=$(addr ATTACKER /tmp/f.log)
FLASH=$(grep -oE 'FLASH=[0-9]+' /tmp/f.log | head -1 | cut -d= -f2)
echo "export POOL=$POOL"; echo "export RWD=$RWD"; echo "export ATTACKER=$ATTACKER"
echo "--- BEFORE ---"
echo "\$ cast call \$POOL \"rewardReserve()(uint256)\" --rpc-url \$RPC";        cast call "$POOL" "rewardReserve()(uint256)" --rpc-url "$RPC"
echo "\$ cast call \$RWD \"balanceOf(address)(uint256)\" \$ATTACKER --rpc-url \$RPC"; cast call "$RWD" "balanceOf(address)(uint256)" "$ATTACKER" --rpc-url "$RPC"
echo "--- the SAME attack, now on the time-weighted pool ---"
echo "attack tx: $(send "$ATTACKER" 'attack(uint256)' "$FLASH")"
echo "--- AFTER: 0 seconds staked = 0 reward; the pot is untouched ---"
echo "\$ cast call \$RWD \"balanceOf(address)(uint256)\" \$ATTACKER --rpc-url \$RPC"; cast call "$RWD" "balanceOf(address)(uint256)" "$ATTACKER" --rpc-url "$RPC"   # 0
echo "\$ cast call \$POOL \"rewardReserve()(uint256)\" --rpc-url \$RPC";        cast call "$POOL" "rewardReserve()(uint256)" --rpc-url "$RPC"   # 100000e18 untouched
echo
echo "############################  DONE  ############################"
