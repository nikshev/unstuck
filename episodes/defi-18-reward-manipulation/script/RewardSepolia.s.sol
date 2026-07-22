// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {MockERC20}    from "../src/MockERC20.sol";
import {IERC20}       from "../src/IERC20.sol";
import {IStakingPool} from "../src/IStakingPool.sol";
import {StakingPool}  from "../src/StakingPool.sol";
import {FlashLender}  from "../src/FlashLender.sol";
import {Attacker}     from "../src/Attacker.sol";

// -----------------------------------------------------------------------------
// Proven on Sepolia (public Etherscan) — the exploit is ATOMIC, so one transaction
// does borrow -> stake -> claim -> unstake -> repay. Before/after read with `cast`:
//   POOL     0xC9774d3717fDB85bfc38934156C679f9b1a592A0
//   RWD      0x6105E4dEB6A0BCE5EB35f989Ace7C074F399EC4e
//   ATTACKER 0x90f07D9191b28f7cfb7066Dbd2f63B05d1c07309   (attack() run from the keeper)
//   BEFORE:  rewardReserve = 100,000 RWD   ·   attacker RWD = 0
//   attack() — the whole exploit in one transaction:
//     https://sepolia.etherscan.io/tx/0x188f9b80fbb5ce6709f96ec2c0c04c2390f717aeebc0f51f1f024e485e7036d5
//   AFTER:   rewardReserve = ~10 RWD       ·   attacker RWD = 99,990   (matches the forge test)
// -----------------------------------------------------------------------------

// Flash-loan reward manipulation — Sepolia deploy for the capstone. Replicates the test setUp:
// a funded reward pot, an honest standing staker (the deployer), a flash lender with liquidity,
// and the Attacker contract. attack() is run AFTERWARD with cast as one clickable tx. Logs every
// address for the orchestrator.
contract RewardSepolia is Script {
    uint256 constant POT    = 100_000e18;    // reward pot
    uint256 constant HONEST =   1_000e18;    // the honest, standing staker
    uint256 constant FLASH  = 10_000_000e18; // borrowed for one tx, repaid same tx

    function run() external {
        vm.startBroadcast();
        MockERC20 lp  = new MockERC20("LP Token", "LP");
        MockERC20 rwd = new MockERC20("Reward",  "RWD");
        StakingPool pool = new StakingPool(IERC20(address(lp)), IERC20(address(rwd)));

        // fund the reward pot
        rwd.mint(msg.sender, POT);
        rwd.approve(address(pool), type(uint256).max);
        pool.fund(POT);

        // the deployer is the honest, long-term staker
        lp.mint(msg.sender, HONEST);
        lp.approve(address(pool), type(uint256).max);
        pool.stake(HONEST);

        // flash lender holds the borrowable LP
        FlashLender lender = new FlashLender(IERC20(address(lp)));
        lp.mint(address(lender), FLASH);

        // the attacker contract (attack() is sent later, as its own tx)
        Attacker atk = new Attacker(IERC20(address(lp)), IERC20(address(rwd)), IStakingPool(address(pool)), lender);
        vm.stopBroadcast();

        console2.log("LP=%s", address(lp));
        console2.log("RWD=%s", address(rwd));
        console2.log("POOL=%s", address(pool));
        console2.log("LENDER=%s", address(lender));
        console2.log("ATTACKER=%s", address(atk));
        console2.log("FLASH=%s", FLASH);
    }
}
