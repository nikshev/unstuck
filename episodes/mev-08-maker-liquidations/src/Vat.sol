// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/// @title  Vat - the MakerDAO core accounting engine (teaching lab, WAD-only)
/// @notice The Vat is Maker's ledger. It records every vault ("urn") on every
///         collateral type ("ilk") as `ink` (collateral locked) and `art`
///         (normalized debt), plus internal DAI balances and unlocked
///         collateral ("gem").
/// @dev    Real Maker mixes WAD(1e18), RAY(1e27) and RAD(1e45) fixed point.
///         For clean, exact teaching numbers this lab uses ONE scale,
///         WAD = 1e18, for every quantity (collateral, debt, prices, ratios).
contract Vat {
    uint256 public constant WAD = 1e18;

    // --- Auth ---
    mapping(address => uint256) public wards;
    modifier auth() {
        require(wards[msg.sender] == 1, "Vat/not-authorized");
        _;
    }
    function rely(address usr) external auth { wards[usr] = 1; }

    // --- Data ---
    struct Ilk {
        uint256 Art;  // total normalized debt for the ilk   [WAD]
        uint256 rate; // accumulated stability-fee rate       [WAD] (1e18 == 1.0x)
        uint256 spot; // safe price = market price / mat       [WAD]
    }
    struct Urn {
        uint256 ink;  // locked collateral                    [WAD]
        uint256 art;  // normalized debt                      [WAD]
    }

    mapping(bytes32 => Ilk)                          public ilks;
    mapping(bytes32 => mapping(address => Urn))      public urns;
    mapping(bytes32 => mapping(address => uint256))  public gem; // unlocked collateral [WAD]
    mapping(address => uint256)                      public dai; // internal DAI        [WAD]
    mapping(address => uint256)                      public sin; // system (bad) debt   [WAD]

    constructor() { wards[msg.sender] = 1; }

    // --- Safe signed add ---
    function _add(uint256 x, int256 y) internal pure returns (uint256 z) {
        z = y >= 0 ? x + uint256(y) : x - uint256(-y);
    }

    // --- Setup helpers (stand in for slip/frob so the lab stays small) ---
    function init(bytes32 ilk, uint256 rate_, uint256 spot_) external auth {
        ilks[ilk].rate = rate_;
        ilks[ilk].spot = spot_;
    }
    function file(bytes32 ilk, bytes32 what, uint256 data) external auth {
        if      (what == "spot") ilks[ilk].spot = data;
        else if (what == "rate") ilks[ilk].rate = data;
        else revert("Vat/file-unrecognized");
    }
    function setUrn(bytes32 ilk, address u, uint256 ink_, uint256 art_) external auth {
        urns[ilk][u].ink = ink_;
        urns[ilk][u].art = art_;
        ilks[ilk].Art    = art_;
    }
    function mintDai(address u, uint256 wad) external auth {
        dai[u] += wad; // stands in for a whale funding a keeper's DAI balance
    }

    // --- Liquidation confiscation (called by the Dog) ---
    /// @notice Pull `dink` collateral and `dart` debt out of an urn: the
    ///         collateral goes to `dst` (the Clipper) and the debt is booked
    ///         as `sin` at `w` (the Vow). `dink`/`dart` are passed negative.
    function grab(
        bytes32 ilk, address u, address dst, address w, int256 dink, int256 dart
    ) external auth {
        Urn storage urn = urns[ilk][u];
        Ilk storage i   = ilks[ilk];

        urn.ink = _add(urn.ink, dink);
        urn.art = _add(urn.art, dart);
        i.Art   = _add(i.Art,   dart);

        int256 dtab = int256(i.rate) * dart / int256(WAD); // debt delta [WAD]
        gem[ilk][dst] = _add(gem[ilk][dst], -dink);        // Clipper receives the collateral
        sin[w]        = _add(sin[w], -dtab);               // Vow inherits the debt
    }

    // --- Transfers (called by the Clipper during take) ---
    function move(address src, address dst, uint256 wad) external {
        require(src == msg.sender || wards[msg.sender] == 1, "Vat/not-allowed");
        dai[src] -= wad;
        dai[dst] += wad;
    }
    function flux(bytes32 ilk, address src, address dst, uint256 wad) external {
        require(src == msg.sender || wards[msg.sender] == 1, "Vat/not-allowed");
        gem[ilk][src] -= wad;
        gem[ilk][dst] += wad;
    }
    /// @notice Mint DAI to `v` and book matching debt as sin at `u`. Used to
    ///         pay the keeper the liquidation-trigger incentive.
    function suck(address u, address v, uint256 wad) external auth {
        sin[u] += wad;
        dai[v] += wad;
    }
}
