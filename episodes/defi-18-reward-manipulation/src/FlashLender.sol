// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "./IERC20.sol";

interface IFlashBorrower { function onFlashLoan(uint256 amount) external; }

/// @notice Minimal flash lender: hands out tokens with no collateral, as long as the same
/// transaction gives them back before it ends. This is the ATOMIC "borrow -> use -> repay".
contract FlashLender {
    IERC20 public immutable token;
    constructor(IERC20 _t) { token = _t; }

    function flashLoan(uint256 amount) external {
        uint256 balBefore = token.balanceOf(address(this));
        require(balBefore >= amount, "insufficient liquidity");
        token.transfer(msg.sender, amount);        // 1. lend
        IFlashBorrower(msg.sender).onFlashLoan(amount);  // 2. borrower does its thing
        require(token.balanceOf(address(this)) >= balBefore, "flash loan not repaid"); // 3. must be whole again
    }
}
