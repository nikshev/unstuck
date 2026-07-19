// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/// @title  Dog - the MakerDAO Liquidation 2.0 trigger module
/// @notice `bark` checks that a vault is unsafe, confiscates its collateral
///         into a Clipper Dutch auction, and books the debt at the Vow. It
///         replaces the old `Cat` from Liquidation 1.0.

interface VatLike {
    function ilks(bytes32) external view returns (uint256 Art, uint256 rate, uint256 spot);
    function urns(bytes32, address) external view returns (uint256 ink, uint256 art);
    function grab(bytes32, address, address, address, int256, int256) external;
}
interface ClipLike {
    function kick(uint256 tab, uint256 lot, address usr, address kpr) external returns (uint256);
}

contract Dog {
    uint256 public constant WAD = 1e18;

    VatLike public immutable vat;
    address public vow;

    struct Ilk {
        address clip; // Clipper auction house for this ilk
        uint256 chop; // liquidation penalty [WAD] (1.12e18 == +12%)
    }
    mapping(bytes32 => Ilk) public ilks;

    address public owner;
    modifier auth() { require(msg.sender == owner, "Dog/not-authorized"); _; }
    constructor(address vat_) { vat = VatLike(vat_); owner = msg.sender; }

    event Bark(bytes32 indexed ilk, address indexed urn, uint256 ink, uint256 art, uint256 tab, address clip, uint256 id);

    function file(bytes32 what, address data) external auth {
        if (what == "vow") vow = data;
        else revert("Dog/file-unrecognized");
    }
    function file(bytes32 ilk, bytes32 what, uint256 data) external auth {
        if (what == "chop") ilks[ilk].chop = data;
        else revert("Dog/file-unrecognized-num");
    }
    function file(bytes32 ilk, bytes32 what, address clip) external auth {
        if (what == "clip") ilks[ilk].clip = clip;
        else revert("Dog/file-unrecognized-clip");
    }

    /// @notice Liquidate an unsafe vault by seizing its collateral into a
    ///         Clipper Dutch auction. Anyone may call it; the caller `kpr`
    ///         earns the auction's trigger incentive.
    function bark(bytes32 ilk, address urn, address kpr) external returns (uint256 id) {
        (, uint256 rate, uint256 spot) = vat.ilks(ilk);
        (uint256 ink, uint256 art)     = vat.urns(ilk, urn);

        // UNSAFE  <=>  collateral value (ink*spot)  <  debt (art*rate)
        require(spot > 0 && ink * spot < art * rate, "Dog/not-unsafe");

        Ilk memory milk = ilks[ilk];
        uint256 dink = ink;  // full liquidation (the lab skips Hole/dirt limits)
        uint256 dart = art;

        // tab = debt * rate * chop  =  DAI the auction must raise (incl. penalty)
        uint256 tab = art * rate / WAD;   // debt value in DAI
        tab = tab * milk.chop / WAD;      // add the liquidation penalty

        // confiscate: collateral -> Clipper, debt -> Vow
        vat.grab(ilk, urn, milk.clip, vow, -int256(dink), -int256(dart));

        // open the auction; the keeper incentive is paid inside kick
        id = ClipLike(milk.clip).kick(tab, dink, urn, kpr);

        emit Bark(ilk, urn, dink, dart, tab, milk.clip, id);
    }
}
