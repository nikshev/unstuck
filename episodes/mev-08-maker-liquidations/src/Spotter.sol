// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/// @title  PriceFeed - stand-in for Maker's OSM / oracle "pip"
/// @notice Holds the current market price of the collateral [WAD].
contract PriceFeed {
    uint256 private val;
    address public owner;
    constructor() { owner = msg.sender; }
    function poke(uint256 wad) external { require(msg.sender == owner, "PriceFeed/not-owner"); val = wad; }
    function read() external view returns (uint256) { return val; }
}

interface VatLike {
    function file(bytes32, bytes32, uint256) external;
}

/// @title  Spotter - pushes safety prices into the Vat
/// @notice `poke` reads the market price from the pip and writes the safe
///         price `spot = price / mat` into the Vat, where `mat` is the
///         liquidation ratio (e.g. 1.5 = 150% collateralization required).
contract Spotter {
    uint256 public constant WAD = 1e18;

    VatLike   public vat;
    PriceFeed public pip;
    mapping(bytes32 => uint256) public mat; // liquidation ratio per ilk [WAD]

    address public owner;
    modifier auth() { require(msg.sender == owner, "Spotter/not-authorized"); _; }
    constructor(address vat_) { vat = VatLike(vat_); owner = msg.sender; }

    function setPip(address pip_) external auth { pip = PriceFeed(pip_); }
    function file(bytes32 ilk, uint256 mat_) external auth { mat[ilk] = mat_; }

    function poke(bytes32 ilk) external {
        uint256 price = pip.read();
        uint256 spot  = price * WAD / mat[ilk]; // wdiv: safe price = price / mat
        vat.file(ilk, "spot", spot);
    }
}
