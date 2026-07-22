// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {MockERC20} from "../src/MockERC20.sol";
import {IERC20} from "../src/IERC20.sol";
import {MiniPool} from "../src/MiniPool.sol";
import {MiniPoolTW} from "../src/MiniPoolTW.sol";
import {Actor, IMiniPool} from "../src/Actor.sol";

uint256 constant PLIQ = 100_000e18;
uint256 constant JLIQ = 9_900_000e18;
uint256 constant SWAP = 100_000e18;

// ACT 1 — passive only
contract PassiveSepolia is Script {
    function run() external {
        vm.startBroadcast();
        MockERC20 t0=new MockERC20("Token0","T0"); MockERC20 t1=new MockERC20("Token1","T1");
        MiniPool pool=new MiniPool(IERC20(address(t0)),IERC20(address(t1)));
        Actor passive=new Actor(IMiniPool(address(pool)),IERC20(address(t0)),IERC20(address(t1)));
        Actor trader=new Actor(IMiniPool(address(pool)),IERC20(address(t0)),IERC20(address(t1)));
        t0.mint(address(passive),PLIQ); t1.mint(address(passive),PLIQ); t1.mint(address(trader),SWAP);
        vm.stopBroadcast();
        console2.log("T1=%s",address(t1)); console2.log("POOL=%s",address(pool));
        console2.log("PASSIVE=%s",address(passive)); console2.log("TRADER=%s",address(trader));
        console2.log("PLIQ=%s",PLIQ); console2.log("SWAP=%s",SWAP);
    }
}
// ACT 2 — passive + JIT (MiniPool)
contract JitSepolia is Script {
    function run() external {
        vm.startBroadcast();
        MockERC20 t0=new MockERC20("Token0","T0"); MockERC20 t1=new MockERC20("Token1","T1");
        MiniPool pool=new MiniPool(IERC20(address(t0)),IERC20(address(t1)));
        Actor passive=new Actor(IMiniPool(address(pool)),IERC20(address(t0)),IERC20(address(t1)));
        Actor jit=new Actor(IMiniPool(address(pool)),IERC20(address(t0)),IERC20(address(t1)));
        Actor trader=new Actor(IMiniPool(address(pool)),IERC20(address(t0)),IERC20(address(t1)));
        t0.mint(address(passive),PLIQ); t1.mint(address(passive),PLIQ);
        t0.mint(address(jit),JLIQ); t1.mint(address(jit),JLIQ); t1.mint(address(trader),SWAP);
        vm.stopBroadcast();
        console2.log("T1=%s",address(t1)); console2.log("POOL=%s",address(pool));
        console2.log("PASSIVE=%s",address(passive)); console2.log("JIT=%s",address(jit)); console2.log("TRADER=%s",address(trader));
        console2.log("PLIQ=%s",PLIQ); console2.log("JLIQ=%s",JLIQ); console2.log("SWAP=%s",SWAP);
    }
}
// ACT 3 — passive + JIT on the time-weighted pool
contract DefendedSepolia is Script {
    function run() external {
        vm.startBroadcast();
        MockERC20 t0=new MockERC20("Token0","T0"); MockERC20 t1=new MockERC20("Token1","T1");
        MiniPoolTW pool=new MiniPoolTW(IERC20(address(t0)),IERC20(address(t1)));
        Actor passive=new Actor(IMiniPool(address(pool)),IERC20(address(t0)),IERC20(address(t1)));
        Actor jit=new Actor(IMiniPool(address(pool)),IERC20(address(t0)),IERC20(address(t1)));
        Actor trader=new Actor(IMiniPool(address(pool)),IERC20(address(t0)),IERC20(address(t1)));
        t0.mint(address(passive),PLIQ); t1.mint(address(passive),PLIQ);
        t0.mint(address(jit),JLIQ); t1.mint(address(jit),JLIQ); t1.mint(address(trader),SWAP);
        vm.stopBroadcast();
        console2.log("T1=%s",address(t1)); console2.log("POOL=%s",address(pool));
        console2.log("PASSIVE=%s",address(passive)); console2.log("JIT=%s",address(jit)); console2.log("TRADER=%s",address(trader));
        console2.log("PLIQ=%s",PLIQ); console2.log("JLIQ=%s",JLIQ); console2.log("SWAP=%s",SWAP);
    }
}
