// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Bare-bones ERC-20 for the lab (LP token + reward token). Infinite approve supported.
/// Emits the STANDARD ERC-20 Transfer/Approval events, so a public explorer (Etherscan) renders
/// the real token flow — who sent what to whom — on every transaction, including the atomic attack.
contract MockERC20 {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory n, string memory s) { name = n; symbol = s; }

    function mint(address to, uint256 a) external {
        balanceOf[to] += a; totalSupply += a;
        emit Transfer(address(0), to, a);
    }
    function approve(address sp, uint256 a) external returns (bool) {
        allowance[msg.sender][sp] = a;
        emit Approval(msg.sender, sp, a);
        return true;
    }
    function transfer(address to, uint256 a) external returns (bool) { _move(msg.sender, to, a); return true; }

    function transferFrom(address f, address to, uint256 a) external returns (bool) {
        uint256 al = allowance[f][msg.sender];
        if (al != type(uint256).max) { require(al >= a, "allowance"); allowance[f][msg.sender] = al - a; }
        _move(f, to, a);
        return true;
    }

    function _move(address f, address to, uint256 a) internal {
        require(balanceOf[f] >= a, "balance");
        balanceOf[f] -= a;
        balanceOf[to] += a;
        emit Transfer(f, to, a);
    }
}
