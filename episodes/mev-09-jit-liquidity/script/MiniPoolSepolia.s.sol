// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {MockERC20} from "../src/MockERC20.sol";
import {IERC20}    from "../src/IERC20.sol";
import {MiniPool}  from "../src/MiniPool.sol";
import {Actor, IMiniPool} from "../src/Actor.sol";

// -----------------------------------------------------------------------------
// Proven on Sepolia (public Etherscan) — five ordered txs wrap ONE swap. Fee split
// read with `cast`: JIT searcher 0.1485 T1 (99%) vs passive LP 0.0015 T1 (1%).
//   POOL     0x2B3A906ddbc1CC3a96D9B632E519453C5a4C9957
//   JIT      0x2D04C5b3ADb0Ddd61a0114689E986DeEe0bDaba5
//   PASSIVE  0xC628D33448e9722622B200d017C358466060e6d4
//   1. JIT add:      https://sepolia.etherscan.io/tx/0x3a11a9afdde43880947ca25ce9d17fade6d278d0d352b9d8cbe36a41717025b4
//   2. swap:         https://sepolia.etherscan.io/tx/0xa37a92e1a0ce666b12870e7abfd5f99f822d2052486fe7c20566223b4f021b8f
//   3. JIT collect:  https://sepolia.etherscan.io/tx/0x5ccd3aa2513f7bbfa27ca491ee19961d50a85ea52f31543006bb33469c062112
//   4. JIT remove:   https://sepolia.etherscan.io/tx/0x839b07251bb18d5aa8bd1fdcde94892cb9252c338c77d41334f5ef20337b4dd9
//   5. passive coll: https://sepolia.etherscan.io/tx/0xf5729ea5196f38121aa32e929b222ecd3fb25b3cd75226c3a1ecfb91f73dbde7
// -----------------------------------------------------------------------------

// JIT liquidity — Sepolia deploy for the capstone. A passive LP is already standing in the pool;
// then (via cast, as ordered clickable txs) the JIT searcher adds a huge position, the trader swaps,
// the searcher collects ~all the fee and burns. Logs every address for the orchestrator.
contract MiniPoolSepolia is Script {
    uint256 constant PASSIVE = 100e18;     // standing liquidity
    uint256 constant JITL    = 9_900e18;   // the JIT position
    uint256 constant SWAPIN  = 50e18;      // the big swap (fee = 0.15)

    function run() external {
        vm.startBroadcast();
        MockERC20 t0 = new MockERC20("Token0", "T0");
        MockERC20 t1 = new MockERC20("Token1", "T1");
        MiniPool pool = new MiniPool(IERC20(address(t0)), IERC20(address(t1)));

        Actor passive = new Actor(IMiniPool(address(pool)), IERC20(address(t0)), IERC20(address(t1)));
        Actor jit     = new Actor(IMiniPool(address(pool)), IERC20(address(t0)), IERC20(address(t1)));
        Actor trader  = new Actor(IMiniPool(address(pool)), IERC20(address(t0)), IERC20(address(t1)));

        t0.mint(address(passive), PASSIVE); t1.mint(address(passive), PASSIVE);
        t0.mint(address(jit), JITL);        t1.mint(address(jit), JITL);
        t1.mint(address(trader), SWAPIN);

        passive.add(PASSIVE);   // the passive LP is already in, before any JIT
        vm.stopBroadcast();

        console2.log("T0=%s", address(t0));
        console2.log("T1=%s", address(t1));
        console2.log("POOL=%s", address(pool));
        console2.log("PASSIVE=%s", address(passive));
        console2.log("JIT=%s", address(jit));
        console2.log("TRADER=%s", address(trader));
        console2.log("JITL=%s", JITL);
        console2.log("SWAPIN=%s", SWAPIN);
    }
}
