// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

interface IUniV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline
    ) external returns (uint256[] memory amounts);
}

/// The classic sandwich on the real Uniswap v2 WETH/USDC pool (mainnet fork, block 20,000,000).
/// A searcher sees a whale's USDC->WETH swap in the mempool, front-runs it (buying WETH cheap,
/// pushing the price up), lets the victim buy at the worse price, then back-runs (selling the WETH
/// back into the now-inflated pool). The victim's slippage is the searcher's profit.
contract SandwichTest is Test {
    IERC20 constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IUniV2Router constant ROUTER = IUniV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address attacker = makeAddr("searcher");
    address victim   = makeAddr("whale");

    uint256 constant FRONT  = 1_000_000e6;   // attacker front-run: $1,000,000 USDC
    uint256 constant VICTIM = 2_000_000e6;   // victim's swap:      $2,000,000 USDC

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), 20_000_000);
        deal(address(USDC), attacker, FRONT);
        deal(address(USDC), victim,  VICTIM);
    }

    function _buyWETH(address who, uint256 usdcIn, uint256 minOut) internal returns (uint256 got) {
        address[] memory path = new address[](2);
        path[0] = address(USDC); path[1] = address(WETH);
        vm.startPrank(who);
        USDC.approve(address(ROUTER), usdcIn);
        uint256[] memory a = ROUTER.swapExactTokensForTokens(usdcIn, minOut, path, who, block.timestamp + 1);
        vm.stopPrank();
        got = a[1];
    }

    function _sellWETH(address who, uint256 wethIn) internal returns (uint256 got) {
        address[] memory path = new address[](2);
        path[0] = address(WETH); path[1] = address(USDC);
        vm.startPrank(who);
        WETH.approve(address(ROUTER), wethIn);
        uint256[] memory a = ROUTER.swapExactTokensForTokens(wethIn, 0, path, who, block.timestamp + 1);
        vm.stopPrank();
        got = a[1];
    }

    /// What the victim WOULD get with no attacker in front of them (fair execution).
    function _fairVictimWETH() internal returns (uint256 fair) {
        uint256 snap = vm.snapshotState();
        fair = _buyWETH(victim, VICTIM, 0);
        vm.revertToState(snap);
    }

    function test_sandwich() public {
        uint256 fair = _fairVictimWETH();
        emit log_named_decimal_uint("victim FAIR out (WETH)", fair, 18);

        // 1) FRONT-RUN: searcher buys WETH first, pushing the price up.
        uint256 atkWeth = _buyWETH(attacker, FRONT, 0);
        emit log_named_decimal_uint("1. front-run: searcher WETH", atkWeth, 18);

        // 2) VICTIM buys at the worse price (no slippage guard) -> gets LESS than fair.
        uint256 gotWeth = _buyWETH(victim, VICTIM, 0);
        emit log_named_decimal_uint("2. victim GOT out (WETH)", gotWeth, 18);
        emit log_named_decimal_uint("   victim shortfall (WETH)", fair - gotWeth, 18);

        // 3) BACK-RUN: searcher sells the WETH back into the inflated pool.
        uint256 back = _sellWETH(attacker, atkWeth);
        emit log_named_decimal_uint("3. back-run: searcher USDC back", back, 6);

        int256 profit = int256(back) - int256(FRONT);
        emit log_named_decimal_int("=> searcher PROFIT (USDC)", profit, 6);

        assertGt(gotWeth, 0);
        assertLt(gotWeth, fair, "victim must get less than fair");
        assertGt(back, FRONT, "searcher must profit");
    }

    /// The defense: the victim sets a realistic slippage guard (amountOutMin). Under the front-run
    /// the pool can no longer deliver it, so the victim's swap REVERTS instead of executing at a
    /// looted price -- and the searcher is left holding WETH they bought high. Sandwich defeated.
    function test_defended() public {
        uint256 fair = _fairVictimWETH();
        uint256 minOut = fair * 995 / 1000;   // accept at most 0.5% slippage

        // searcher still front-runs...
        _buyWETH(attacker, FRONT, 0);

        // ...but the victim's guarded swap now can't be filled and reverts.
        address[] memory path = new address[](2);
        path[0] = address(USDC); path[1] = address(WETH);
        vm.startPrank(victim);
        USDC.approve(address(ROUTER), VICTIM);
        vm.expectRevert(bytes("UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT"));
        ROUTER.swapExactTokensForTokens(VICTIM, minOut, path, victim, block.timestamp + 1);
        vm.stopPrank();

        emit log_string("victim's 0.5% slippage guard reverted the sandwiched swap -> attack defeated");
    }
}
