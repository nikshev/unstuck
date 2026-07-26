// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// A real (minimal) ERC-20 so the Sepolia capstone shows "Tokens Transferred"
// rows on Etherscan and real `cast send approve` / transferFrom work on-chain.
contract Underlying {
    string public name = "Lab wstETH";
    string public symbol = "wstETH";
    uint8  public decimals = 18;
    uint256 public totalSupply;
    mapping(address=>uint256) public balanceOf;
    mapping(address=>mapping(address=>uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function mint(address to,uint256 v) external { totalSupply+=v; balanceOf[to]+=v; emit Transfer(address(0),to,v); }
    function approve(address s,uint256 v) external returns(bool){ allowance[msg.sender][s]=v; emit Approval(msg.sender,s,v); return true; }
    function transfer(address to,uint256 v) external returns(bool){ _move(msg.sender,to,v); return true; }
    function transferFrom(address f,address to,uint256 v) external returns(bool){
        uint256 a=allowance[f][msg.sender];
        if(a!=type(uint256).max){ allowance[f][msg.sender]=a-v; }
        _move(f,to,v); return true;
    }
    function _move(address f,address to,uint256 v) internal { balanceOf[f]-=v; balanceOf[to]+=v; emit Transfer(f,to,v); }
}
