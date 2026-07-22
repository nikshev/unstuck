// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {MockERC20} from "../src/MockERC20.sol";
import {IERC20} from "../src/IERC20.sol";
import {IStakingPool} from "../src/IStakingPool.sol";
import {StakingPool} from "../src/StakingPool.sol";
import {StakeActor} from "../src/StakeActor.sol";

// ACT 1 (honest) — Sepolia deploy. Alice + Bob each get 1,000 LP; they stake and Alice claims via
// cast, as clickable txs. Alice owns half the pool, so she earns half the pot.
// -----------------------------------------------------------------------------
// Proven on Sepolia (public Etherscan) — Alice staked half, so she earned half:
//   POOL  0xE8Cd4De743e28513b6d824A8b7Aa07c2EDcce273
//   ALICE 0x7D5A26C0852B7A2163BaD07352ED3f3E69091c77 · BOB 0xcD373C7194c7e274D36326eC8865C9EB0fc28782
//   Alice stake: https://sepolia.etherscan.io/tx/0x041201063cbb48072bea53d918ecda57eddf38c1d6d84270261fdf70970a8cb5
//   Bob   stake: https://sepolia.etherscan.io/tx/0xf585f93a38d9175b15f4af368cdf02961905a85ab9a356ba07ae96525b9d653c
//   total staked = 2,000 -> Alice = HALF
//   Alice claim: https://sepolia.etherscan.io/tx/0x3ccb09fc55f0aed1ccc2f341f8c146f155428983880454ce32e553a921cce096
//   -> Alice reward = 50,000 RWD (half the pot); 50,000 left for Bob
// -----------------------------------------------------------------------------
contract HonestSepolia is Script {
    uint256 constant POT   = 100_000e18;
    uint256 constant STAKE =   1_000e18;
    function run() external {
        vm.startBroadcast();
        MockERC20 lp  = new MockERC20("LP Token", "LP");
        MockERC20 rwd = new MockERC20("Reward",  "RWD");
        StakingPool pool = new StakingPool(IERC20(address(lp)), IERC20(address(rwd)));
        rwd.mint(msg.sender, POT); rwd.approve(address(pool), type(uint256).max); pool.fund(POT);
        StakeActor alice = new StakeActor(IStakingPool(address(pool)), IERC20(address(lp)));
        StakeActor bob   = new StakeActor(IStakingPool(address(pool)), IERC20(address(lp)));
        lp.mint(address(alice), STAKE);
        lp.mint(address(bob), STAKE);
        vm.stopBroadcast();
        console2.log("LP=%s", address(lp));
        console2.log("RWD=%s", address(rwd));
        console2.log("POOL=%s", address(pool));
        console2.log("ALICE=%s", address(alice));
        console2.log("BOB=%s", address(bob));
        console2.log("STAKE=%s", STAKE);
    }
}
