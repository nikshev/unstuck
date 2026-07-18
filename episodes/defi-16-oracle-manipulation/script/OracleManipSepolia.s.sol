// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

// -- Proven on Sepolia (public Etherscan) via a Chainstack node, in 3 consecutive blocks ------
//   weth 0xb6a148c334181a427937084c4f3c4f0eb0d9de4b   usd     0x0c8c2ea7dfb94d919c6cfd040397caf6c88fb85a
//   pool 0xe47821598750ecf831de8c85cd7f978e4f8a5ca7   lending 0x0d6bbdcf0f0b630e53fb72d3c27bfc7a8557f9d5
//   1 PUMP    https://sepolia.etherscan.io/tx/0xe8f03800482fe6d419a849689fd37684fcaa6281d6f979d38b8f3197ee90f191  (800k USD -> WETH, spot 2,000 -> 49,880)
//   2 DEPOSIT https://sepolia.etherscan.io/tx/0xf20aafc6ab9a0fd953fbdf6c339b45246157f64a4f701fcf7c6141e490f6aa44  (79.95 WETH collateral)
//   3 BORROW  https://sepolia.etherscan.io/tx/0x9e383b2b2a172d30b67bb2326f2085f1c5de44246bab5b458fa423eab9e1c407  (borrow 1,000,000 USD = drain, +200k)
// --------------------------------------------------------------------------------------------


/// Demo token — emits Transfer so Etherscan shows the flows; allowance-free (throwaway tokens).
contract MockERC20 {
    string public name; string public symbol; uint8 public decimals;
    mapping(address => uint256) public balanceOf;
    event Transfer(address indexed from, address indexed to, uint256 value);
    constructor(string memory n, string memory s, uint8 d) { name = n; symbol = s; decimals = d; }
    function mint(address to, uint256 a) external { balanceOf[to] += a; emit Transfer(address(0), to, a); }
    function transfer(address to, uint256 a) external returns (bool) { balanceOf[msg.sender] -= a; balanceOf[to] += a; emit Transfer(msg.sender, to, a); return true; }
    function transferFrom(address f, address t, uint256 a) external returns (bool) { balanceOf[f] -= a; balanceOf[t] += a; emit Transfer(f, t, a); return true; }
}

/// Constant-product DEX pool WETH/USD. Its live spot price is the naive oracle.
contract DexPool {
    MockERC20 public weth; MockERC20 public usd;
    uint256 public rWeth; uint256 public rUsd;
    event Swap(address indexed who, uint256 usdIn, uint256 wethOut);
    constructor(MockERC20 w, MockERC20 u) { weth = w; usd = u; }
    function seed(uint256 w, uint256 u) external { weth.transferFrom(msg.sender, address(this), w); usd.transferFrom(msg.sender, address(this), u); rWeth += w; rUsd += u; }
    function _out(uint256 aIn, uint256 rin, uint256 rout) internal pure returns (uint256) { uint256 f = aIn * 997; return f * rout / (rin * 1000 + f); }
    function buyWeth(uint256 usdIn) external returns (uint256 out) { out = _out(usdIn, rUsd, rWeth); usd.transferFrom(msg.sender, address(this), usdIn); weth.transfer(msg.sender, out); rUsd += usdIn; rWeth -= out; emit Swap(msg.sender, usdIn, out); }
    function spotPriceUSDPerWETH() external view returns (uint256) { return rUsd * 1e18 / rWeth; }
}

interface IOracle { function priceWETH() external view returns (uint256); }
contract SpotOracle is IOracle { DexPool public pool; constructor(DexPool p){pool=p;} function priceWETH() external view returns (uint256){ return pool.spotPriceUSDPerWETH(); } }

/// Naive money market: deposit WETH, borrow USD up to collateral x spot price. (Vulnerable oracle.)
contract LendingPool {
    MockERC20 public weth; MockERC20 public usd; IOracle public oracle;
    mapping(address => uint256) public collateral; mapping(address => uint256) public debt;
    event Deposit(address indexed who, uint256 weth); event Borrow(address indexed who, uint256 usd);
    constructor(MockERC20 w, MockERC20 u, IOracle o){ weth = w; usd = u; oracle = o; }
    function fund(uint256 a) external { usd.transferFrom(msg.sender, address(this), a); }
    function depositAll() external { uint256 w = weth.balanceOf(msg.sender); weth.transferFrom(msg.sender, address(this), w); collateral[msg.sender] += w; emit Deposit(msg.sender, w); }
    function maxBorrow(address user) public view returns (uint256) { return collateral[user] * oracle.priceWETH() / 1e18; }
    function borrow(uint256 u) external { require(debt[msg.sender] + u <= maxBorrow(msg.sender), "undercollateralized"); debt[msg.sender] += u; usd.transfer(msg.sender, u); emit Borrow(msg.sender, u); }
}

/// Deploy the lab on Sepolia. The 3 attack steps (pump / deposit / borrow) are sent AFTER, via cast send,
/// so each is its own tx you can click through on Etherscan.
contract OracleManipSepolia is Script {
    function run() external {
        uint256 pk = vm.envUint("PK");
        address attacker = vm.addr(pk);

        vm.startBroadcast(pk);
        MockERC20 weth = new MockERC20("Mock WETH", "mWETH", 18);
        MockERC20 usd  = new MockERC20("Mock USD",  "mUSD",  18);
        DexPool pool   = new DexPool(weth, usd);
        SpotOracle oracle = new SpotOracle(pool);
        LendingPool lending = new LendingPool(weth, usd, oracle);
        // seed the DEX pool: 100 WETH / 200,000 USD -> spot $2,000/WETH
        weth.mint(attacker, 100e18);
        usd.mint(attacker, 200_000e18 + 800_000e18);   // 200k to seed + 800k attack capital (the "flash loan")
        pool.seed(100e18, 200_000e18);
        // fund the lending pool with $1,000,000 to lend
        usd.mint(attacker, 1_000_000e18);
        usd.transfer(address(lending), 1_000_000e18);
        vm.stopBroadcast();

        console2.log("weth   ", address(weth));
        console2.log("usd    ", address(usd));
        console2.log("pool   ", address(pool));
        console2.log("lending", address(lending));
        console2.log("attacker", attacker);
    }
}
