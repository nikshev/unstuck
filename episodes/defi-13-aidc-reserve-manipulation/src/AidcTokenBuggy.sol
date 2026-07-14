// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
interface IPair { function sync() external; }
// BUGGY fee-on-transfer token: its burn logic burns tokens OUT OF THE PAIR (not the seller),
// then calls sync() — shrinking the AIDC reserve while WBNB is untouched, so AIDC's price spikes.
contract AidcTokenBuggy {
    string public name="AIDC"; string public symbol="AIDC"; uint8 public decimals=18;
    uint256 public totalSupply;
    mapping(address=>uint256) public balanceOf;
    function mint(address to,uint256 a) external { balanceOf[to]+=a; totalSupply+=a; }
    function transfer(address to,uint256 a) external returns(bool){ require(balanceOf[msg.sender]>=a,"bal"); balanceOf[msg.sender]-=a; balanceOf[to]+=a; return true; }
    function transferFrom(address f,address to,uint256 a) external returns(bool){ require(balanceOf[f]>=a,"bal"); balanceOf[f]-=a; balanceOf[to]+=a; return true; }
    // ⚠️ THE BUG: burns AIDC from the PAIR's balance, then syncs -> deflates the reserve.
    function executeAccumulatedBurn(address pair, uint256 amount) external {
        balanceOf[pair] -= amount; totalSupply -= amount;   // burn from the POOL, not the seller
        IPair(pair).sync();                                 // reserve now artificially small
    }
}
