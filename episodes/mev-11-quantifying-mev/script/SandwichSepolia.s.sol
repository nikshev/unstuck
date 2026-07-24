// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {MockERC20} from "../src/MockERC20.sol";
import {IERC20} from "../src/IERC20.sol";
import {Pool} from "../src/Pool.sol";
import {Searcher, IPool} from "../src/Searcher.sol";

// Sepolia deploy of a sandwich lab. The deployer is the VICTIM (it will make the big swap).
// A Searcher contract front-runs and back-runs it. frontrun/victim/backrun are sent as 3 cast txs.
contract SandwichSepolia is Script {
    function run() external {
        vm.startBroadcast();
        MockERC20 weth  = new MockERC20("Wrapped Ether", "WETH");
        MockERC20 token = new MockERC20("Token",        "TKN");
        Pool pool = new Pool(IERC20(address(weth)), IERC20(address(token)));
        // liquidity: 100 WETH : 100,000 TKN
        weth.mint(msg.sender, 130e18); token.mint(msg.sender, 100_000e18);
        weth.approve(address(pool), type(uint256).max);
        token.approve(address(pool), type(uint256).max);
        pool.init(100e18, 100_000e18);
        // the searcher, funded with 10 WETH to sandwich with
        Searcher s = new Searcher(IPool(address(pool)), IERC20(address(weth)), IERC20(address(token)));
        weth.mint(address(s), 10e18);
        vm.stopBroadcast();
        console2.log("WETH=%s", address(weth));
        console2.log("TOKEN=%s", address(token));
        console2.log("POOL=%s", address(pool));
        console2.log("SEARCHER=%s", address(s));
    }
}
