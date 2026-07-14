// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
contract MockWBNB {
    string public name="Wrapped BNB"; string public symbol="WBNB"; uint8 public decimals=18;
    mapping(address=>uint256) public balanceOf;
    function mint(address to,uint256 a) external { balanceOf[to]+=a; }
    function transfer(address to,uint256 a) external returns(bool){ require(balanceOf[msg.sender]>=a,"bal"); balanceOf[msg.sender]-=a; balanceOf[to]+=a; return true; }
}
