// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// A payout vault. A trusted SIGNER approves "pay `amount` to `to`" by signing it off-chain;
// the recipient submits that signature to pull the payout. ecrecover proves the signer approved it.
// ❌ VULNERABLE — it never records that a signature was USED, so the same one can be REPLAYED.
contract Vault {
    address public signer;
    uint256 public pool;
    mapping(address => uint256) public paid;
    constructor(address _signer, uint256 _pool) { signer = _signer; pool = _pool; }
    function claim(address to, uint256 amount, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 hash = keccak256(abi.encodePacked(to, amount));
        require(ecrecover(hash, v, r, s) == signer, "bad signature");
        require(amount <= pool, "insufficient pool");
        pool -= amount;
        paid[to] += amount;
    }
}

// ✅ FIXED — record each signature and reject it the second time (one-time use).
contract VaultFixed {
    address public signer;
    uint256 public pool;
    mapping(address => uint256) public paid;
    mapping(bytes32 => bool) public used;
    constructor(address _signer, uint256 _pool) { signer = _signer; pool = _pool; }
    function claim(address to, uint256 amount, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 hash = keccak256(abi.encodePacked(to, amount));
        require(ecrecover(hash, v, r, s) == signer, "bad signature");
        bytes32 sigId = keccak256(abi.encodePacked(r, s, v));
        require(!used[sigId], "signature already used");
        used[sigId] = true;
        require(amount <= pool, "insufficient pool");
        pool -= amount;
        paid[to] += amount;
    }
}

// A valid signature by SIGNER over (TO, 100 ether). Hardcoded so Remix/Sepolia can replay it
// without an off-chain signer. (Generated with vm.sign(0xB0B, keccak256(TO, 100 ether)).)
abstract contract Signed {
    address internal constant SIGNER = 0x0376AAc07Ad725E01357B1725B5ceC61aE10473c;
    address internal constant TO     = address(0xA11CE);
    uint256 internal constant AMT    = 100 ether;
    uint8   internal constant V = 27;
    bytes32 internal constant R = 0x90f0ff39b8375e7933d3018380edcb7e749c32d085eb73f32c20dd6bc20edb6f;
    bytes32 internal constant S = 0x0a3d156879134d770dac42a9b85e6749aa89ea81ddb42bb486bc4ca39d56f173;
}

// ▶ Attacker vs the VULNERABLE vault. Do it MANUALLY:
//   poolLeft() -> claimOnce() -> replayOnce() -> poolLeft() -> drain() -> poolLeft()/myLoot()
contract Attacker_OLD is Signed {
    Vault public vault;
    constructor() { vault = new Vault(SIGNER, 1000 ether); }
    function claimOnce()  external { vault.claim(TO, AMT, V, R, S); }               // 1 legit claim
    function replayOnce() external { vault.claim(TO, AMT, V, R, S); }               // SAME sig again
    function drain()      external { for (uint i=0;i<8;i++) vault.claim(TO,AMT,V,R,S); }  // finish the drain
    function poolLeft()   external view returns (uint256) { return vault.pool() / 1e18; }
    function myLoot()     external view returns (uint256) { return vault.paid(TO) / 1e18; }
}

// ▶ Same attacker vs the FIXED vault. replayOnce() reverts.
contract Attacker_NEW is Signed {
    VaultFixed public vault;
    constructor() { vault = new VaultFixed(SIGNER, 1000 ether); }
    function claimOnce()  external { vault.claim(TO, AMT, V, R, S); }
    function replayOnce() external { vault.claim(TO, AMT, V, R, S); }               // reverts
    function poolLeft()   external view returns (uint256) { return vault.pool() / 1e18; }
    function myLoot()     external view returns (uint256) { return vault.paid(TO) / 1e18; }
}
