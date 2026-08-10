// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MockToken} from "./MockToken.sol";
import {IOracle} from "./Oracles.sol";

/// @title LendingPool — deposit MNGO as collateral, borrow USDC against it.
/// The whole safety of the market rests on ONE number: what is your MNGO worth?
/// That number comes from `oracle.price()`. Point it at a manipulable spot price
/// and an attacker can make their collateral appear worth anything they like.
///
/// This is a faithful, teaching-sized reproduction of the Mango Markets exploit
/// (Oct 2022, ~$114M): pump the collateral token's price, borrow against the
/// inflated value, and walk away with the treasury.
contract LendingPool {
    MockToken public mngo;   // collateral token
    MockToken public usdc;   // borrowable token
    IOracle public oracle;
    uint256 public constant LTV = 80; // borrow up to 80% of collateral value

    mapping(address => uint256) public collateral; // MNGO deposited
    mapping(address => uint256) public debt;        // USDC borrowed

    event Borrowed(address indexed who, uint256 usdc, uint256 collateralValue);

    constructor(MockToken _mngo, MockToken _usdc, IOracle _oracle) {
        mngo = _mngo;
        usdc = _usdc;
        oracle = _oracle;
    }

    /// USDC value of an account's MNGO collateral, per the oracle.
    function collateralValue(address who) public view returns (uint256) {
        return collateral[who] * oracle.price() / 1e18;
    }

    function deposit(uint256 mngoAmount) external {
        mngo.transferFrom(msg.sender, address(this), mngoAmount);
        collateral[msg.sender] += mngoAmount;
    }

    function borrow(uint256 usdcAmount) external {
        uint256 maxDebt = collateralValue(msg.sender) * LTV / 100;
        require(debt[msg.sender] + usdcAmount <= maxDebt, "undercollateralized");
        debt[msg.sender] += usdcAmount;
        usdc.transfer(msg.sender, usdcAmount);
        emit Borrowed(msg.sender, usdcAmount, collateralValue(msg.sender));
    }
}
