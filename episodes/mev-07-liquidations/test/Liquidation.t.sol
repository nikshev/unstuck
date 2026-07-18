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

/// A minimal Aave-style money market: WETH collateral, USD debt, an injectable price oracle,
/// an 80% liquidation threshold, and an 8% liquidation bonus paid to whoever repays a bad loan.
contract LendingPool {
    Mock public weth; Mock public usd;
    uint256 public priceWETH;          // USD per WETH, 1e18-scaled (the oracle)
    uint256 public constant LT = 80;   // liquidation threshold, %
    uint256 public constant BONUS = 8; // liquidation bonus, %
    mapping(address => uint256) public collateral;
    mapping(address => uint256) public debt;
    event Liquidate(address indexed liquidator, address indexed user, uint256 repaid, uint256 seizedWeth);

    constructor(Mock w, Mock u) { weth = w; usd = u; }
    function setPrice(uint256 p) external { priceWETH = p; }
    function fund(uint256 usdAmt) external { usd.transferFrom(msg.sender, address(this), usdAmt); }
    function deposit(uint256 w) external { weth.transferFrom(msg.sender, address(this), w); collateral[msg.sender] += w; }
    function borrow(uint256 u) external {
        debt[msg.sender] += u;
        require(healthFactor(msg.sender) >= 1e18, "unhealthy");
        usd.transfer(msg.sender, u);
    }

    /// HF = collateralValue * LT% / debt, scaled 1e18. HF < 1e18 => liquidatable.
    function healthFactor(address user) public view returns (uint256) {
        if (debt[user] == 0) return type(uint256).max;
        uint256 collVal = collateral[user] * priceWETH / 1e18;      // USD (1e18)
        return collVal * LT / 100 * 1e18 / debt[user];
    }

    /// Repay `repayUsd` of an unhealthy loan and seize collateral worth repayUsd * (1 + BONUS).
    function liquidate(address user, uint256 repayUsd) external returns (uint256 seizedWeth) {
        require(healthFactor(user) < 1e18, "healthy - cannot liquidate");
        seizedWeth = repayUsd * (100 + BONUS) / 100 * 1e18 / priceWETH;  // collateral + 8% bonus
        usd.transferFrom(msg.sender, address(this), repayUsd);          // liquidator repays the debt
        debt[user] -= repayUsd;
        collateral[user] -= seizedWeth;
        weth.transfer(msg.sender, seizedWeth);                          // liquidator receives collateral
        emit Liquidate(msg.sender, user, repayUsd, seizedWeth);
    }
}

contract LiquidationTest is Test {
    Mock weth; Mock usd; LendingPool pool;
    address borrower   = makeAddr("borrower");
    address liquidator = makeAddr("liquidator");

    function setUp() public {
        weth = new Mock("Wrapped Ether", "WETH", 18);
        usd  = new Mock("USD Coin", "USDC", 18);
        pool = new LendingPool(weth, usd);
        pool.setPrice(2000e18);                          // WETH = $2,000
        usd.mint(address(this), 1_000_000e18);           // seed the pool with USD to lend
        usd.transfer(address(pool), 1_000_000e18);
        weth.mint(borrower, 100e18);                     // borrower's collateral
    }

    function test_liquidation() public {
        // 1) borrower opens a healthy loan: 100 WETH ($200k) collateral, borrow $150k
        vm.startPrank(borrower);
        pool.deposit(100e18);
        pool.borrow(150_000e18);
        vm.stopPrank();
        emit log_named_decimal_uint("HF at $2000 (>=1.0 = healthy)", pool.healthFactor(borrower), 18);

        // 2) the market drops: WETH $2,000 -> $1,700. The position goes underwater.
        pool.setPrice(1700e18);
        emit log_named_decimal_uint("HF at $1700 (<1.0 = liquidatable)", pool.healthFactor(borrower), 18);
        assertLt(pool.healthFactor(borrower), 1e18, "position should be underwater");

        // 3) a searcher liquidates: repay half the debt ($75k), seize collateral + the 8% bonus
        uint256 repaid = 75_000e18;
        usd.mint(liquidator, repaid);
        vm.startPrank(liquidator);
        uint256 seized = pool.liquidate(borrower, repaid);
        vm.stopPrank();

        uint256 seizedValueUsd = seized * 1700e18 / 1e18;        // USD value at the current price
        emit log_named_decimal_uint("WETH seized", seized, 18);
        emit log_named_decimal_uint("seized collateral value (USD)", seizedValueUsd, 18);
        emit log_named_decimal_uint("USD repaid by liquidator", repaid, 18);
        emit log_named_decimal_int("=> liquidator PROFIT (USD, the bonus)", int256(seizedValueUsd) - int256(repaid), 18);

        assertGt(seizedValueUsd, repaid, "liquidator must seize MORE value than they repaid (the bonus)");
    }
}
