// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice A one-shot on-chain opportunity: the FIRST caller takes the whole prize.
/// Think of it as any MEV opportunity - an arbitrage, a liquidation - where only one
/// transaction can capture the value, and only if it lands first in the block.
contract Opportunity {
    uint256 public prize = 1 ether; // the value up for grabs
    address public winner;          // who captured it (zero until taken)

    /// The first caller wins everything; everyone after them reverts.
    function take() external returns (uint256 won) {
        require(winner == address(0), "already taken");
        winner = msg.sender;
        won = prize;
        prize = 0;
    }
}
