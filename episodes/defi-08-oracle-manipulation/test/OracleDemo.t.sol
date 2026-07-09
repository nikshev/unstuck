// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/OracleDemo.sol";

contract OracleDemoTest is Test {
    function test_OLD_OracleManipulation_DrainsPool() public {
        Attacker_OLD atk = new Attacker_OLD();
        // Honest state: 1 COLL is worth 1000 USD; the lender holds 1,000,000 USD.
        emit log_named_uint("oracle price (honest)   ", atk.oraclePrice());
        emit log_named_uint("pool liquidity (USD)    ", atk.poolLiquidity());
        assertEq(atk.oraclePrice(), 1000);
        assertEq(atk.poolLiquidity(), 1_000_000);

        // STEP 1: one big (flash-loaned) swap spikes the spot price the oracle trusts.
        atk.manipulate();
        emit log_named_uint("oracle price (manipulated)", atk.oraclePrice());
        assertEq(atk.oraclePrice(), 100_000, "spot price inflated 100x");

        // STEP 2: deposit 20 COLL, borrow the whole pool at the fake price.
        atk.drain();
        emit log_named_uint("pool liquidity after     ", atk.poolLiquidity());
        emit log_named_uint("attacker loot (USD)      ", atk.myLoot());
        assertEq(atk.poolLiquidity(), 0, "pool fully drained");
        assertEq(atk.myLoot(), 1_000_000, "took 1,000,000 USD for 20 COLL of collateral");
    }

    function test_FIXED_TrustedOracle_Reverts() public {
        Attacker_NEW atk = new Attacker_NEW();
        assertEq(atk.oraclePrice(), 1000);
        // The AMM still moves...
        atk.manipulate();
        emit log_named_uint("oracle price after swap", atk.oraclePrice());
        assertEq(atk.oraclePrice(), 1000, "trusted oracle ignores the swap");
        // ...but the lender's trusted price does not, so the over-borrow reverts.
        vm.expectRevert(bytes("undercollateralized"));
        atk.drain();
        emit log_named_uint("pool liquidity (untouched)", atk.poolLiquidity());
        assertEq(atk.poolLiquidity(), 1_000_000, "pool safe");
    }
}
