// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {MockERC20} from "../src/MockERC20.sol";
import {IERC20} from "../src/IERC20.sol";
import {MiniPool} from "../src/MiniPool.sol";
import {MiniPoolTW} from "../src/MiniPoolTW.sol";
import {Actor, IMiniPool} from "../src/Actor.sol";
import {JitBundle, IPool} from "../src/JitBundle.sol";

uint256 constant PLIQ = 100_000e18;      // passive, standing liquidity
uint256 constant JLIQ = 9_900_000e18;    // JIT floods in -> ~99% of the pool
uint256 constant SWAP = 100_000e18;      // the big swap; fee = 0.3% = 300 T1

// ACT 1 — passive LP earns the whole fee (the normal flow)
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
// ACT 2 — JIT sandwich (atomic bundle) on the PLAIN pool -> JIT scoops ~99%
contract JitSepolia is Script {
    function run() external {
        vm.startBroadcast();
        MockERC20 t0=new MockERC20("Token0","T0"); MockERC20 t1=new MockERC20("Token1","T1");
        MiniPool pool=new MiniPool(IERC20(address(t0)),IERC20(address(t1)));
        Actor passive=new Actor(IMiniPool(address(pool)),IERC20(address(t0)),IERC20(address(t1)));
        JitBundle bundle=new JitBundle(IPool(address(pool)),IERC20(address(t0)),IERC20(address(t1)));
        t0.mint(address(passive),PLIQ); t1.mint(address(passive),PLIQ);
        t0.mint(address(bundle),JLIQ);  t1.mint(address(bundle),JLIQ+SWAP);
        vm.stopBroadcast();
        console2.log("T1=%s",address(t1)); console2.log("POOL=%s",address(pool));
        console2.log("PASSIVE=%s",address(passive)); console2.log("BUNDLE=%s",address(bundle));
        console2.log("PLIQ=%s",PLIQ); console2.log("JLIQ=%s",JLIQ); console2.log("SWAP=%s",SWAP);
    }
}
// ACT 3 — the SAME atomic JIT bundle on the TIME-WEIGHTED pool -> JIT earns ~0
contract DefendedSepolia is Script {
    function run() external {
        vm.startBroadcast();
        MockERC20 t0=new MockERC20("Token0","T0"); MockERC20 t1=new MockERC20("Token1","T1");
        MiniPoolTW pool=new MiniPoolTW(IERC20(address(t0)),IERC20(address(t1)));
        Actor passive=new Actor(IMiniPool(address(pool)),IERC20(address(t0)),IERC20(address(t1)));
        JitBundle bundle=new JitBundle(IPool(address(pool)),IERC20(address(t0)),IERC20(address(t1)));
        t0.mint(address(passive),PLIQ); t1.mint(address(passive),PLIQ);
        t0.mint(address(bundle),JLIQ);  t1.mint(address(bundle),JLIQ+SWAP);
        vm.stopBroadcast();
        console2.log("T1=%s",address(t1)); console2.log("POOL=%s",address(pool));
        console2.log("PASSIVE=%s",address(passive)); console2.log("BUNDLE=%s",address(bundle));
        console2.log("PLIQ=%s",PLIQ); console2.log("JLIQ=%s",JLIQ); console2.log("SWAP=%s",SWAP);
    }
}
