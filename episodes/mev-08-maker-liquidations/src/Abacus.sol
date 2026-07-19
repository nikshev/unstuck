// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/// @title Abacus - the price-decay calculator interface used by the Clipper
interface Abacus {
    /// @param top The starting price of the auction   [WAD]
    /// @param dur Seconds elapsed since the auction started
    /// @return    The current auction price            [WAD]
    function price(uint256 top, uint256 dur) external view returns (uint256);
}

/// @title  LinearDecrease - a straight-line Dutch-auction price curve
/// @notice price = top * (tau - dur) / tau   for dur < tau, else 0.
///         The price falls in a straight line from `top` down to zero over
///         `tau` seconds. This is the simplest real Maker Abacus.
contract LinearDecrease is Abacus {
    uint256 public tau; // seconds for the price to decay from top to zero

    address public owner;
    modifier auth() { require(msg.sender == owner, "LinearDecrease/not-authorized"); _; }
    constructor() { owner = msg.sender; }

    function file(bytes32 what, uint256 data) external auth {
        if (what == "tau") tau = data;
        else revert("LinearDecrease/file-unrecognized");
    }

    function price(uint256 top, uint256 dur) external view returns (uint256) {
        if (dur >= tau) return 0;
        return top * (tau - dur) / tau;
    }
}
