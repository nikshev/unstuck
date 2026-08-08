// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// Minimal ERC20 used as the pool's underlying asset in the lab.
contract MockToken {
    string public name = "Mock USD"; string public symbol = "mUSD"; uint8 public decimals = 18;
    mapping(address=>uint256) public balanceOf;
    mapping(address=>mapping(address=>uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 v);
    event Approval(address indexed o, address indexed s, uint256 v);
    function mint(address to, uint256 amt) external { balanceOf[to]+=amt; emit Transfer(address(0),to,amt); }
    function approve(address s, uint256 v) external returns(bool){ allowance[msg.sender][s]=v; emit Approval(msg.sender,s,v); return true; }
    function transfer(address to, uint256 v) external returns(bool){ _t(msg.sender,to,v); return true; }
    function transferFrom(address f, address to, uint256 v) external returns(bool){
        uint256 a=allowance[f][msg.sender]; if(a!=type(uint256).max) allowance[f][msg.sender]=a-v; _t(f,to,v); return true; }
    function _t(address f,address to,uint256 v) internal { balanceOf[f]-=v; balanceOf[to]+=v; emit Transfer(f,to,v); }
}
