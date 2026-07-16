// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {MockWETH} from "./MockWETH.sol";
// Illustrative reconstruction of an integer-overflow drain (Flooring/DN404-class, 2026).
// Deposit WETH -> get an equal `credit` (a claim on the vault). Redeem credit for WETH.
// BUG: a "settle" step subtracts inside an `unchecked` block. Solidity 0.8 normally reverts on
// underflow, but `unchecked` re-enables the 2018-era wrap: subtract more than you have and the
// credit WRAPS to ~uint256.max. (In the real bug, a second accounting path fed the oversized value.)
contract ClaimVaultBuggy {
    MockWETH public weth;
    mapping(address=>uint256) public credit;
    constructor(address w){ weth=MockWETH(w); }

    function deposit(uint256 a) external { weth.transferFrom(msg.sender,address(this),a); credit[msg.sender]+=a; }

    // ⚠️ the vulnerable line: unchecked subtraction can underflow the credit
    function settle(uint256 fee) external {
        unchecked { credit[msg.sender] = credit[msg.sender] - fee; }   // wraps if fee > credit
    }

    function redeem(uint256 a) external {
        require(credit[msg.sender] >= a, "no credit");   // passes: credit is astronomically inflated
        unchecked { credit[msg.sender] -= a; }
        weth.transfer(msg.sender, a);
    }
}
