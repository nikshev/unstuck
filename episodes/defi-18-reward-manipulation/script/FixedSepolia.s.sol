// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {MockERC20} from "../src/MockERC20.sol";
import {IERC20} from "../src/IERC20.sol";
import {IStakingPool} from "../src/IStakingPool.sol";
import {StakingPoolFixed} from "../src/StakingPoolFixed.sol";
import {StakeActor} from "../src/StakeActor.sol";
import {FlashLender} from "../src/FlashLender.sol";
import {Attacker} from "../src/Attacker.sol";

// ACT 3 (fix) — Sepolia deploy. The TIME-WEIGHTED pool, an honest staker, and the SAME attacker.
// attack() is run afterward with cast; it earns 0 because 0 seconds elapse.
// -----------------------------------------------------------------------------
// Proven on Sepolia (public Etherscan) — the SAME flash attack that drained the broken pool earns 0:
//   POOL     0x717f1651562dcEdEaEe9a8e5A0775AE7a0373b3e
//   ATTACKER 0x3dE6C3a8E2Bb67F70F28987997e8B583728FD475
//   BEFORE: pot = 100,000 RWD · attacker = 0
//   attack: https://sepolia.etherscan.io/tx/0xda4f03d90ff9e226e3f90d4b43ca0888e09e0254eba08abe84b3301410220010
//   AFTER:  attacker = 0 (0 seconds staked = 0 reward) · pot = 100,000 (untouched)
// -----------------------------------------------------------------------------
contract FixedSepolia is Script {
    uint256 constant POT   = 100_000e18;
    uint256 constant STAKE =   1_000e18;
    uint256 constant FLASH = 10_000_000e18;
    function run() external {
        vm.startBroadcast();
        MockERC20 lp  = new MockERC20("LP Token", "LP");
        MockERC20 rwd = new MockERC20("Reward",  "RWD");
        StakingPoolFixed pool = new StakingPoolFixed(IERC20(address(lp)), IERC20(address(rwd)));
        rwd.mint(msg.sender, POT); rwd.approve(address(pool), type(uint256).max); pool.fund(POT, 1e18);
        StakeActor alice = new StakeActor(IStakingPool(address(pool)), IERC20(address(lp)));
        lp.mint(address(alice), STAKE); alice.stake(STAKE);
        FlashLender lender = new FlashLender(IERC20(address(lp))); lp.mint(address(lender), FLASH);
        Attacker atk = new Attacker(IERC20(address(lp)), IERC20(address(rwd)), IStakingPool(address(pool)), lender);
        vm.stopBroadcast();
        console2.log("POOL=%s", address(pool));
        console2.log("RWD=%s", address(rwd));
        console2.log("ATTACKER=%s", address(atk));
        console2.log("FLASH=%s", FLASH);
    }
}
