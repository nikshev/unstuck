// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {MockWETH} from "./MockWETH.sol";
// FIXED: no `unchecked` on security-critical accounting. Solidity 0.8's checked math reverts on
// underflow for free — a subtraction of more than you hold now reverts instead of wrapping.
contract ClaimVaultFixed {
    MockWETH public weth;
    mapping(address=>uint256) public credit;
    constructor(address w){ weth=MockWETH(w); }

    function deposit(uint256 a) external { weth.transferFrom(msg.sender,address(this),a); credit[msg.sender]+=a; }

    function settle(uint256 fee) external {
        credit[msg.sender] = credit[msg.sender] - fee;   // checked: reverts on underflow (0.8)
    }

    function redeem(uint256 a) external {
        require(credit[msg.sender] >= a, "no credit");
        credit[msg.sender] -= a;
        weth.transfer(msg.sender, a);
    }
}
