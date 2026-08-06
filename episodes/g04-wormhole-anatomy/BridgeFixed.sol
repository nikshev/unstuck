// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// The fix is small but total: verify the signatures against the bridge's OWN
/// stored guardian set — never a set the caller supplies.
contract BridgeFixed {
    address[] public guardians;
    uint256 public quorum;
    mapping(bytes32 => bool) public used;
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;
    event Mint(address indexed to, uint256 amount);

    constructor(address[] memory _g, uint256 _q) { guardians = _g; quorum = _q; }

    function digest(address to, uint256 amount, uint256 nonce) public view returns (bytes32) {
        bytes32 h = keccak256(abi.encodePacked(to, amount, nonce, address(this)));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
    }

    // ─────────────────────────  THE ONLY CHANGE FROM Bridge.sol  ─────────────────────────
    //  BEFORE (vulnerable):  receiveAndMint(..., address[] claimedGuardians, bytes[] sigs)
    //                            require(_in( claimedGuardians , signer))   // list from the CALLER
    //   AFTER   (fixed):     receiveAndMint(...,                    bytes[] sigs)   // no caller list
    //                            require(_in( guardians , signer))          // the contract's OWN list
    // ─────────────────────────────────────────────────────────────────────────────────────
    function receiveAndMint(address to, uint256 amount, uint256 nonce, bytes[] calldata sigs) external {
        bytes32 d = digest(to, amount, nonce);
        require(!used[d], "already minted");
        uint256 count; address last;
        for (uint256 i; i < sigs.length; i++) {
            address signer = _recover(d, sigs[i]);
            require(_in(guardians, signer), "not a guardian");   // ← the REAL, stored set (not the caller's)
            require(uint160(signer) > uint160(last), "unsorted/dup");
            last = signer; count++;
        }
        require(count >= quorum, "not enough signatures");
        used[d] = true;
        balanceOf[to] += amount; totalSupply += amount;
        emit Mint(to, amount);
    }

    function _in(address[] storage set, address a) internal view returns (bool) {
        for (uint256 i; i < set.length; i++) if (set[i] == a) return true;
        return false;
    }
    function _recover(bytes32 d, bytes memory sig) internal pure returns (address) {
        require(sig.length == 65, "bad sig");
        bytes32 r; bytes32 s; uint8 v;
        assembly { r := mload(add(sig,32)) s := mload(add(sig,64)) v := byte(0,mload(add(sig,96))) }
        return ecrecover(d, v, r, s);
    }
    receive() external payable {}
}
