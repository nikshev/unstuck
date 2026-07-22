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

/// @notice Three acts, each logging who holds what BEFORE and AFTER every step:
///   1. test_honest — how honest staking pays a FAIR, proportional share
///   2. test_drain  — how a flash loan FAKES a giant stake and scoops the pot
///   3. test_fixed  — how time-weighting makes that same attack earn nothing
contract RewardManipTest is Test {
    MockERC20 lp;
    MockERC20 rwd;
    address alice = makeAddr("alice");
    address bob   = makeAddr("bob");

    uint256 constant POT   = 100_000e18;    // reward pot to share out
    uint256 constant STAKE =   1_000e18;    // an honest stake
    uint256 constant FLASH = 10_000_000e18; // flash-loaned for one tx, repaid same tx

    function setUp() public {
        lp  = new MockERC20("LP Token", "LP");
        rwd = new MockERC20("Reward",  "RWD");
    }

    function _stake(address pool, address who, uint256 amt) internal {
        lp.mint(who, amt);
        vm.startPrank(who);
        lp.approve(pool, type(uint256).max);
        StakingPool(pool).stake(amt);
        vm.stopPrank();
    }

    // -----------------------------------------------------------------------
    // ACT 1 — HONEST STAKING: your reward is proportional to your real stake
    // -----------------------------------------------------------------------
    function test_honest() public {
        StakingPool pool = new StakingPool(IERC20(address(lp)), IERC20(address(rwd)));
        rwd.mint(address(this), POT);
        rwd.approve(address(pool), type(uint256).max);
        pool.fund(POT);

        console.log("=== ACT 1: HONEST STAKING (fair, proportional) ===");
        console.log("reward pot to share (RWD):", POT / 1e18);
        console.log("");
        _stake(address(pool), alice, STAKE);
        console.log("Alice stakes (LP):        ", STAKE / 1e18);
        _stake(address(pool), bob, STAKE);
        console.log("Bob   stakes (LP):        ", STAKE / 1e18);
        console.log("total staked (LP):        ", pool.totalStaked() / 1e18);
        console.log("-> Alice owns 1,000 of 2,000 = HALF the pool");
        console.log("");
        console.log("Alice RWD before claim:   ", rwd.balanceOf(alice) / 1e18);
        vm.prank(alice);
        uint256 got = pool.claim();
        console.log("Alice RWD after claim:    ", got / 1e18);
        console.log("-> she earned HALF the pot: her fair, proportional share");
        console.log("pot still left (for Bob): ", pool.rewardReserve() / 1e18);

        assertApproxEqAbs(got, POT / 2, 1e18, "honest Alice earns her proportional 50%");
    }

    // -----------------------------------------------------------------------
    // ACT 2 — THE ATTACK: a flash loan fakes a giant stake for one transaction
    // -----------------------------------------------------------------------
    function test_drain() public {
        StakingPool pool = new StakingPool(IERC20(address(lp)), IERC20(address(rwd)));
        rwd.mint(address(this), POT);
        rwd.approve(address(pool), type(uint256).max);
        pool.fund(POT);
        _stake(address(pool), alice, STAKE);   // one honest staker is already in

        FlashLender lender = new FlashLender(IERC20(address(lp)));
        lp.mint(address(lender), FLASH);
        Attacker atk = new Attacker(IERC20(address(lp)), IERC20(address(rwd)), IStakingPool(address(pool)), lender);

        console.log("=== ACT 2: FLASH-LOAN ATTACK ===");
        console.log("reward pot (RWD):         ", pool.rewardReserve() / 1e18);
        console.log("honest Alice staked (LP): ", STAKE / 1e18);
        console.log("");
        console.log("attacker OWN LP (capital):", lp.balanceOf(address(atk)) / 1e18);
        console.log("attacker RWD before:      ", rwd.balanceOf(address(atk)) / 1e18);
        console.log("flash loan available (LP):", FLASH / 1e18);
        console.log("");
        console.log("--- ONE tx: borrow 10,000,000 -> stake -> claim -> unstake -> repay ---");
        atk.attack(FLASH);
        console.log("attacker staked vs Alice:  10,000,000 LP  vs  1,000 LP  -> ~99.99% of the pool");
        console.log("attacker RWD after (loot):", rwd.balanceOf(address(atk)) / 1e18);
        console.log("attacker OWN LP after:    ", lp.balanceOf(address(atk)) / 1e18);
        console.log("-> loan repaid, $0 of its own money spent");
        console.log("pot left for honest Alice:", pool.rewardReserve() / 1e18);

        assertGt(rwd.balanceOf(address(atk)), POT * 999 / 1000, "attacker scoops ~the whole pot");
        assertEq(lp.balanceOf(address(atk)), 0, "flash loan repaid");
    }

    // -----------------------------------------------------------------------
    // ACT 3 — THE FIX: time-weighted rewards -> a same-block stake earns 0
    // -----------------------------------------------------------------------
    function test_fixed() public {
        StakingPoolFixed pool = new StakingPoolFixed(IERC20(address(lp)), IERC20(address(rwd)));
        rwd.mint(address(this), POT);
        rwd.approve(address(pool), type(uint256).max);
        pool.fund(POT, 1e18);   // drip 1 RWD/second, over time

        lp.mint(alice, STAKE);
        vm.startPrank(alice);
        lp.approve(address(pool), type(uint256).max);
        pool.stake(STAKE);
        vm.stopPrank();

        FlashLender lender = new FlashLender(IERC20(address(lp)));
        lp.mint(address(lender), FLASH);
        Attacker atk = new Attacker(IERC20(address(lp)), IERC20(address(rwd)), IStakingPool(address(pool)), lender);

        console.log("=== ACT 3: THE FIX (time-weighted rewards) ===");
        console.log("reward pot (RWD):         ", pool.rewardReserve() / 1e18);
        console.log("attacker RWD before:      ", rwd.balanceOf(address(atk)) / 1e18);
        console.log("");
        console.log("--- SAME flash attack: borrow -> stake -> claim -> unstake -> repay, one tx ---");
        atk.attack(FLASH);
        console.log("seconds the attacker was staked: 0");
        console.log("time-weighted reward = rate x 0 x share = 0");
        console.log("attacker RWD after:       ", rwd.balanceOf(address(atk)) / 1e18);
        console.log("-> the flash whale earns NOTHING");
        console.log("pot untouched (RWD):      ", pool.rewardReserve() / 1e18);

        assertEq(rwd.balanceOf(address(atk)), 0, "same-block stake earns zero on the fixed pool");
    }
}
