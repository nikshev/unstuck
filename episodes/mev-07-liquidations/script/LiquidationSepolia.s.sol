// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

// -- Proven on Sepolia (public Etherscan) via a Chainstack node, in 3 consecutive blocks ------
//   weth 0x04c82e3c6b6d6f9cd05cefca48b2662839b1f791   usd  0x21c2867948ac13d81bdabf650b082751c8c583cf
//   pool 0x7e13f21f9da4a7f441adb9f1866098c27bf68945
//   1 BORROW    https://sepolia.etherscan.io/tx/0x4dc031868f456252a1bbef58ab3e45c6de40044c9ad3599de517ba695b74d11a  (100 WETH -> borrow 150,000 USD, HF 1.07)
//   2 PRICEDROP https://sepolia.etherscan.io/tx/0xe35660393a9ac736539be0ff279e7b8e916621b0f45ef5e6a89fd760461462a4  (oracle 2,000 -> 1,700, HF 0.91 underwater)
//   3 LIQUIDATE https://sepolia.etherscan.io/tx/0x71de1ca4fd4a6ccece9167483e92bb2351928ec291cdf8b22d8bc85ac0e6d5ce  (repay 75k, seize 47.6 WETH = +6k bonus)
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

/// Aave-style money market: WETH collateral, USD debt, injectable price oracle, 80% liquidation
/// threshold, 8% liquidation bonus.
contract LendingPool {
    MockERC20 public weth; MockERC20 public usd;
    uint256 public priceWETH;          // USD per WETH, 1e18-scaled (the oracle)
    uint256 public constant LT = 80;   // liquidation threshold, %
    uint256 public constant BONUS = 8; // liquidation bonus, %
    mapping(address => uint256) public collateral; mapping(address => uint256) public debt;
    event Deposit(address indexed who, uint256 weth);
    event Borrow(address indexed who, uint256 usd);
    event Liquidate(address indexed liquidator, address indexed user, uint256 repaid, uint256 seizedWeth);
    constructor(MockERC20 w, MockERC20 u) { weth = w; usd = u; }
    function setPrice(uint256 p) external { priceWETH = p; }
    function fund(uint256 a) external { usd.transferFrom(msg.sender, address(this), a); }
    function healthFactor(address user) public view returns (uint256) {
        if (debt[user] == 0) return type(uint256).max;
        uint256 collVal = collateral[user] * priceWETH / 1e18;
        return collVal * LT / 100 * 1e18 / debt[user];
    }
    /// borrower posts WETH and draws USD in one tx (must stay healthy)
    function openLoan(uint256 wethAmt, uint256 usdAmt) external {
        weth.transferFrom(msg.sender, address(this), wethAmt); collateral[msg.sender] += wethAmt; emit Deposit(msg.sender, wethAmt);
        debt[msg.sender] += usdAmt; require(healthFactor(msg.sender) >= 1e18, "unhealthy"); usd.transfer(msg.sender, usdAmt); emit Borrow(msg.sender, usdAmt);
    }
    /// anyone can repay a bad loan and seize collateral + the 8% bonus
    function liquidate(address user, uint256 repayUsd) external returns (uint256 seizedWeth) {
        require(healthFactor(user) < 1e18, "healthy - cannot liquidate");
        seizedWeth = repayUsd * (100 + BONUS) / 100 * 1e18 / priceWETH;
        usd.transferFrom(msg.sender, address(this), repayUsd);
        debt[user] -= repayUsd; collateral[user] -= seizedWeth;
        weth.transfer(msg.sender, seizedWeth);
        emit Liquidate(msg.sender, user, repayUsd, seizedWeth);
    }
}

/// Deploy the money market on Sepolia. The 3 story steps (open loan / price drop / liquidate) are sent
/// AFTER, via cast send, so each is its own tx you can click through on Etherscan.
contract LiquidationSepolia is Script {
    function run() external {
        uint256 pk = vm.envUint("PK");
        address liquidator = vm.addr(pk);                 // the deployer is also the searcher/liquidator
        uint256 bpk = uint256(keccak256("mev07-borrower-v1"));
        address borrower = vm.addr(bpk);

        vm.startBroadcast(pk);
        MockERC20 weth = new MockERC20("Mock WETH", "mWETH", 18);
        MockERC20 usd  = new MockERC20("Mock USD",  "mUSD",  18);
        LendingPool pool = new LendingPool(weth, usd);
        pool.setPrice(2000e18);                           // WETH = $2,000
        usd.mint(liquidator, 1_000_000e18 + 75_000e18);   // seed the pool + the liquidator's repay capital
        usd.transfer(address(pool), 1_000_000e18);
        weth.mint(borrower, 100e18);                       // the borrower's collateral
        payable(borrower).transfer(0.05 ether);           // gas for the borrower's own tx
        vm.stopBroadcast();

        console2.log("weth   ", address(weth));
        console2.log("usd    ", address(usd));
        console2.log("pool   ", address(pool));
        console2.log("liquidator", liquidator);
        console2.log("borrower  ", borrower);
    }
}
