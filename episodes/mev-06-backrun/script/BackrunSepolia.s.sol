// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

// -- Proven on Sepolia (public Etherscan) via a Chainstack node, in 3 consecutive blocks ------
//   weth 0x540eb0c8491b6e2336ab0c8d4ec3765df3bbb27f   usdc  0xaa59729c98f9c4c15003c64b4902bb0abe445d17
//   uni  0x91b297ccce90bbfb7349dbf7adaa635dd3302921   sushi 0xbd047aea92dcaf48058d5e249f9ecd2630f1f329
//   1 WHALE  https://sepolia.etherscan.io/tx/0x8ebd58bc0112f463bcb36bfc300bd4e8cff07bf577efc89a92fe5d44e94ad653  (3M USDC -> 987 WETH, de-pegs UNI)
//   2 BUY    https://sepolia.etherscan.io/tx/0x53152df94f92a3bd741ce36400a75da7c9acb3ecdde9cb1407bf9512adb0b609  (500K USDC -> 165.9 WETH on Sushi)
//   3 SELL   https://sepolia.etherscan.io/tx/0x1b76d85086d5276fb7330a7dff630e0a7b305caf209d63a26d902fbbdebf90b5  (165.9 WETH -> 505,294 USDC on Uni = +5,294)
// --------------------------------------------------------------------------------------------


/// Minimal demo token — emits Transfer so Etherscan shows the WETH/USDC flows.
/// allowance-free transferFrom (these are throwaway demo tokens) so the pools can
/// pull funds without a separate approve tx cluttering the story.
contract MockERC20 {
    string public name; string public symbol; uint8 public decimals;
    mapping(address => uint256) public balanceOf;
    event Transfer(address indexed from, address indexed to, uint256 value);
    constructor(string memory n, string memory s, uint8 d) { name = n; symbol = s; decimals = d; }
    function mint(address to, uint256 a) external { balanceOf[to] += a; emit Transfer(address(0), to, a); }
    function transfer(address to, uint256 a) external returns (bool) { balanceOf[msg.sender] -= a; balanceOf[to] += a; emit Transfer(msg.sender, to, a); return true; }
    function transferFrom(address f, address t, uint256 a) external returns (bool) { balanceOf[f] -= a; balanceOf[t] += a; emit Transfer(f, t, a); return true; }
}

/// Minimal constant-product AMM (Uniswap-v2 style x*y=k, 0.3% fee), one WETH/USDC pool.
contract Pool {
    MockERC20 public weth; MockERC20 public usdc;
    uint256 public rWeth; uint256 public rUsdc;
    event Swap(address indexed who, address indexed tokenIn, uint256 amountIn, uint256 amountOut);
    constructor(MockERC20 w, MockERC20 u) { weth = w; usdc = u; }
    function seed(uint256 w, uint256 u) external { weth.transferFrom(msg.sender, address(this), w); usdc.transferFrom(msg.sender, address(this), u); rWeth += w; rUsdc += u; }
    function _out(uint256 amtIn, uint256 rin, uint256 rout) internal pure returns (uint256) { uint256 f = amtIn * 997; return f * rout / (rin * 1000 + f); }
    /// USDC in -> WETH out
    function buyWeth(uint256 usdcIn) external returns (uint256 out) {
        out = _out(usdcIn, rUsdc, rWeth);
        usdc.transferFrom(msg.sender, address(this), usdcIn); weth.transfer(msg.sender, out);
        rUsdc += usdcIn; rWeth -= out; emit Swap(msg.sender, address(usdc), usdcIn, out);
    }
    /// sell the caller's WHOLE WETH balance -> USDC out
    function sellAllWeth() external returns (uint256 out) {
        uint256 amtIn = weth.balanceOf(msg.sender);
        out = _out(amtIn, rWeth, rUsdc);
        weth.transferFrom(msg.sender, address(this), amtIn); usdc.transfer(msg.sender, out);
        rWeth += amtIn; rUsdc -= out; emit Swap(msg.sender, address(weth), amtIn, out);
    }
    function priceUSDCperWETH() external view returns (uint256) { return rUsdc * 1e18 / rWeth; } // 6-dp fixed
}

/// Deploy a two-pool WETH/USDC lab on Sepolia and set up the backrun story.
/// The whale's swap and the searcher's two arb legs are sent AFTER, via `cast send`,
/// so their order (whale de-pegs UNI -> searcher backruns) is real and each is its own tx.
contract BackrunSepolia is Script {
    function run() external {
        uint256 pk = vm.envUint("PK");
        address searcher = vm.addr(pk);
        uint256 wpk = uint256(keccak256("mev06-whale-v1"));
        address whale = vm.addr(wpk);

        vm.startBroadcast(pk);
        MockERC20 weth = new MockERC20("Mock WETH", "mWETH", 18);
        MockERC20 usdc = new MockERC20("Mock USDC", "mUSDC", 6);
        Pool uni   = new Pool(weth, usdc);
        Pool sushi = new Pool(weth, usdc);
        // deployer(=searcher) mints seed liquidity for both pools + keeps 500k USDC arb capital
        weth.mint(searcher, 200_000e18);
        usdc.mint(searcher, 600_500_000e6);
        uni.seed(100_000e18, 300_000_000e6);      // 1 pool: 100k WETH / 300M USDC -> 3000 USDC/WETH
        sushi.seed(100_000e18, 300_000_000e6);
        // fund the whale: 3,000,000 USDC + a little ETH so it can send its own swap tx
        usdc.mint(whale, 3_000_000e6);
        payable(whale).transfer(0.05 ether);
        vm.stopBroadcast();

        console2.log("weth    ", address(weth));
        console2.log("usdc    ", address(usdc));
        console2.log("uni     ", address(uni));
        console2.log("sushi   ", address(sushi));
        console2.log("searcher", searcher);
        console2.log("whale   ", whale);
        console2.log("whaleKey");
        console2.logBytes32(bytes32(wpk));
    }
}
