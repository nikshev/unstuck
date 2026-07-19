// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/// @title  Vow - the MakerDAO "system balance sheet"
/// @notice In real Maker the Vow runs surplus (flap) and debt (flop) auctions.
///         In this lab it is simply the address that inherits a liquidated
///         vault's debt (`sin`) and collects the DAI raised by the auction.
///         After a healthy liquidation:  vow.dai - vow.sin  = the surplus
///         buffer created by the liquidation penalty (chop).
contract Vow {
    address public immutable vat;
    constructor(address vat_) { vat = vat_; }
}
