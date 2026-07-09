// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// A tiny constant-product AMM (COLL <-> USD). Spot price = usdReserve / collReserve.
// One BIG swap moves the spot price a lot, in a single transaction — that is the whole problem.
contract MockAMM {
    uint256 public collReserve;
    uint256 public usdReserve;
    constructor(uint256 c, uint256 u) { collReserve = c; usdReserve = u; }
    // price of 1 COLL in USD, 1e18-scaled
    function spotPrice() public view returns (uint256) { return usdReserve * 1e18 / collReserve; }
    // swap USD in -> COLL out (constant product); pumps COLL's spot price UP
    function swapUSDForColl(uint256 usdIn) external returns (uint256 collOut) {
        uint256 k = collReserve * usdReserve;
        usdReserve += usdIn;
        uint256 newColl = k / usdReserve;
        collOut = collReserve - newColl;
        collReserve = newColl;
    }
}

interface IOracle { function price() external view returns (uint256); }

// A minimal lender: holds a USD pool, lets you borrow USD against COLL collateral,
// valuing that collateral through an oracle. (LTV 100% for a clean demo.)
contract LendingPool {
    IOracle public oracle;
    uint256 public usdLiquidity;                 // USD available to lend
    mapping(address => uint256) public collateral;
    mapping(address => uint256) public debt;
    constructor(IOracle o, uint256 usd) { oracle = o; usdLiquidity = usd; }
    function depositCollateral(uint256 amt) external { collateral[msg.sender] += amt; }
    function borrow(uint256 usdAmount) external {
        // how much USD your collateral is "worth" — straight from the oracle
        uint256 maxDebt = collateral[msg.sender] * oracle.price() / 1e18;
        require(debt[msg.sender] + usdAmount <= maxDebt, "undercollateralized");
        require(usdAmount <= usdLiquidity, "not enough liquidity");
        debt[msg.sender] += usdAmount;
        usdLiquidity -= usdAmount;
    }
    function liquidityLeft() external view returns (uint256) { return usdLiquidity; }
}

// ❌ VULNERABLE oracle — reports the AMM's SPOT price. Manipulable in one transaction.
contract SpotOracle is IOracle {
    MockAMM public amm;
    constructor(MockAMM a) { amm = a; }
    function price() external view returns (uint256) { return amm.spotPrice(); }
}

// ✅ FIXED oracle — a trusted, manipulation-resistant feed (Chainlink / a TWAP).
// A momentary AMM swap cannot move it.
contract TrustedOracle is IOracle {
    uint256 public immutable fixedPrice;
    constructor(uint256 p) { fixedPrice = p; }
    function price() external view returns (uint256) { return fixedPrice; }
}

// ▶ Attacker vs the SPOT-oracle lender. Deploy, then do it MANUALLY, step by step:
//   oraclePrice() -> poolLiquidity() -> manipulate() -> oraclePrice() -> drain() -> poolLiquidity()/myLoot()
contract Attacker_OLD {
    MockAMM public amm;
    LendingPool public lender;
    uint256 public looted;
    constructor() {
        amm    = new MockAMM(1000 ether, 1_000_000 ether);   // honest price = 1000 USD / COLL
        lender = new LendingPool(new SpotOracle(amm), 1_000_000 ether);
    }
    function oraclePrice()   external view returns (uint256) { return lender.oracle().price() / 1e18; }
    function poolLiquidity() external view returns (uint256) { return lender.liquidityLeft() / 1e18; }
    // STEP 1 — flash-loaned USD pumps COLL's spot price (manipulate the oracle)
    function manipulate() external { amm.swapUSDForColl(9_000_000 ether); }
    // STEP 2 — deposit a little COLL, borrow the WHOLE pool at the fake price
    function drain() external {
        lender.depositCollateral(20 ether);
        uint256 take = lender.liquidityLeft();
        lender.borrow(take);
        looted += take;
    }
    function myLoot() external view returns (uint256) { return looted / 1e18; }
}

// ▶ Same attacker vs the FIXED (trusted-oracle) lender. drain() now reverts.
contract Attacker_NEW {
    MockAMM public amm;
    LendingPool public lender;
    uint256 public looted;
    constructor() {
        amm    = new MockAMM(1000 ether, 1_000_000 ether);
        lender = new LendingPool(new TrustedOracle(1000 ether), 1_000_000 ether);  // honest 1000 USD/COLL
    }
    function oraclePrice()   external view returns (uint256) { return lender.oracle().price() / 1e18; }
    function poolLiquidity() external view returns (uint256) { return lender.liquidityLeft() / 1e18; }
    function manipulate() external { amm.swapUSDForColl(9_000_000 ether); }
    function drain() external {
        lender.depositCollateral(20 ether);
        uint256 take = lender.liquidityLeft();
        lender.borrow(take);                 // reverts: trusted price keeps collateral worth only ~20k
        looted += take;
    }
    function myLoot() external view returns (uint256) { return looted / 1e18; }
}
