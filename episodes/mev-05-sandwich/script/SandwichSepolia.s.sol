// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

// -- Proven on Sepolia (public Etherscan) via a Chainstack node -------------------------------
//   pair 0x86cf62a40ba014de5578ed7a385191e5399ac8a2
//   1 FRONT   https://sepolia.etherscan.io/tx/0x44e2b1cb93e0f7416f402f9440a61a3a5e5f523b30586e7dc583f7285ebba29b  (front-run buy)
//   2 VICTIM  https://sepolia.etherscan.io/tx/0xa942a1d87a8ad531afe369e4756a9e2d8ca85286249e29525a7c5a687c49e822  (2M USDC -> 463.75 WETH)
//   3 BACK    https://sepolia.etherscan.io/tx/0x921d74cd2b830631512959bf715d3f36b0778d5b85518905d29d7083bc6c17fd  (back-run sell)
// --------------------------------------------------------------------------------------------


/// Minimal ERC20 (emits Transfer/Approval so Etherscan shows the token flows).
contract Mock20 {
    string public name; string public symbol; uint8 public decimals;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    constructor(string memory n, string memory s, uint8 d) { name = n; symbol = s; decimals = d; }
    function mint(address to, uint256 a) external { balanceOf[to] += a; emit Transfer(address(0), to, a); }
    function approve(address sp, uint256 a) external returns (bool) { allowance[msg.sender][sp] = a; emit Approval(msg.sender, sp, a); return true; }
    function transfer(address to, uint256 a) external returns (bool) { balanceOf[msg.sender] -= a; balanceOf[to] += a; emit Transfer(msg.sender, to, a); return true; }
    function transferFrom(address f, address t, uint256 a) external returns (bool) {
        allowance[f][msg.sender] -= a; balanceOf[f] -= a; balanceOf[t] += a; emit Transfer(f, t, a); return true;
    }
}

/// Minimal constant-product AMM (USDC/WETH), 0.3% fee — the pool a searcher sandwiches.
contract MiniPair {
    Mock20 public usdc; Mock20 public weth;
    uint256 public rU; uint256 public rW;   // cached reserves
    event Swap(address indexed who, string dir, uint256 amtIn, uint256 amtOut);
    constructor(address u, address w) { usdc = Mock20(u); weth = Mock20(w); }
    function sync() public { rU = usdc.balanceOf(address(this)); rW = weth.balanceOf(address(this)); }
    function buyWETH(uint256 usdcIn, address to) external returns (uint256 out) {
        usdc.transferFrom(msg.sender, address(this), usdcIn);
        uint256 inAfter = usdcIn * 997 / 1000;
        out = rW * inAfter / (rU + inAfter);
        weth.transfer(to, out); sync(); emit Swap(msg.sender, "USDC->WETH", usdcIn, out);
    }
    function sellWETH(uint256 wethIn, address to) external returns (uint256 out) {
        weth.transferFrom(msg.sender, address(this), wethIn);
        uint256 inAfter = wethIn * 997 / 1000;
        out = rU * inAfter / (rW + inAfter);
        usdc.transfer(to, out); sync(); emit Swap(msg.sender, "WETH->USDC", wethIn, out);
    }
}

/// Deploy a deep USDC/WETH pool, then run a live sandwich as three separate txs:
///   1) searcher front-run buy   2) whale buy (victim)   3) searcher back-run sell
/// The whale is a distinct address so Etherscan clearly shows two different actors.
contract SandwichSepolia is Script {
    function run() external {
        uint256 pk = vm.envUint("PK");
        address searcher = vm.addr(pk);
        uint256 wpk = uint256(keccak256("mev05-whale-v1"));
        address whale = vm.addr(wpk);
        vm.deal(searcher, 1 ether);   // local-sim only; real Sepolia balance used on --broadcast

        vm.startBroadcast(pk);
        Mock20 usdc = new Mock20("Mock USDC", "mUSDC", 6);
        Mock20 weth = new Mock20("Mock WETH", "mWETH", 18);
        MiniPair pair = new MiniPair(address(usdc), address(weth));
        usdc.mint(address(pair), 54_000_000e6);         // $54,000,000  (mirrors the real pool)
        weth.mint(address(pair), 13_500e18);            // 13,500 WETH  -> ~$4,000
        pair.sync();
        usdc.mint(searcher, 1_000_000e6);
        usdc.mint(whale, 2_000_000e6);
        payable(whale).transfer(0.05 ether);            // gas for the whale's own tx
        usdc.approve(address(pair), type(uint256).max);
        weth.approve(address(pair), type(uint256).max);
        uint256 fair = _quoteBuy(pair, 2_000_000e6);    // what the whale would fairly get
        uint256 atk = pair.buyWETH(1_000_000e6, searcher);      // TX 1: FRONT-RUN ($1M)
        vm.stopBroadcast();

        vm.startBroadcast(wpk);
        usdc.approve(address(pair), type(uint256).max);
        uint256 got = pair.buyWETH(2_000_000e6, whale);         // TX 2: VICTIM buys high ($2M)
        vm.stopBroadcast();

        vm.startBroadcast(pk);
        uint256 back = pair.sellWETH(atk, searcher);            // TX 3: BACK-RUN sell
        vm.stopBroadcast();

        console2.log("pair  ", address(pair));
        console2.log("usdc  ", address(usdc));
        console2.log("weth  ", address(weth));
        console2.log("searcher", searcher);
        console2.log("whale   ", whale);
        console2.log("whale fair WETH (1e15)", fair / 1e3);
        console2.log("whale got  WETH (1e15)", got / 1e3);
        console2.log("front WETH (1e15)     ", atk / 1e3);
        console2.log("back USDC              ", back);
        console2.log("searcher profit USDC   ", back >= 1_000_000e6 ? back - 1_000_000e6 : 0);
    }
    function _quoteBuy(MiniPair p, uint256 usdcIn) internal view returns (uint256) {
        uint256 inAfter = usdcIn * 997 / 1000;
        return p.rW() * inAfter / (p.rU() + inAfter);
    }
}
