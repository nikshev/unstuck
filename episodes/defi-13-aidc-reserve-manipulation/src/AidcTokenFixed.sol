// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
// FIXED: a burn must debit the account that OWES it (the seller/caller) — never the pool, and it
// never pokes the AMM's sync(). A caller can only burn what they actually hold, so the pool reserves
// can't be manipulated.
contract AidcTokenFixed {
    string public name="AIDC"; string public symbol="AIDC"; uint8 public decimals=18;
    uint256 public totalSupply;
    mapping(address=>uint256) public balanceOf;
    function mint(address to,uint256 a) external { balanceOf[to]+=a; totalSupply+=a; }
    function transfer(address to,uint256 a) external returns(bool){ require(balanceOf[msg.sender]>=a,"bal"); balanceOf[msg.sender]-=a; balanceOf[to]+=a; return true; }
    function transferFrom(address f,address to,uint256 a) external returns(bool){ require(balanceOf[f]>=a,"bal"); balanceOf[f]-=a; balanceOf[to]+=a; return true; }
    function executeAccumulatedBurn(address, uint256 amount) external {
        balanceOf[msg.sender] -= amount; totalSupply -= amount;   // burn from the SELLER (checked); no sync
    }
}
