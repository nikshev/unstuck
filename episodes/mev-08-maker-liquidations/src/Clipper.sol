// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/// @title  Clipper - the MakerDAO Liquidation 2.0 Dutch auction house
/// @notice One Clipper runs the collateral auctions for one ilk. `kick` starts
///         an auction at `top` (a price ABOVE market), and the price then
///         DECAYS over time via an Abacus calculator. Keepers call `take` to
///         buy collateral at the current, falling price.

interface VatLike {
    function move(address, address, uint256) external;
    function flux(bytes32, address, address, uint256) external;
    function suck(address, address, uint256) external;
}
interface SpotterLike { function pip() external view returns (address); }
interface PipLike     { function read() external view returns (uint256); }
interface AbacusLike  { function price(uint256, uint256) external view returns (uint256); }

contract Clipper {
    uint256 public constant WAD = 1e18;

    bytes32     public immutable ilk;
    VatLike     public immutable vat;
    SpotterLike public immutable spotter;

    AbacusLike public calc; // price-decay curve (LinearDecrease)
    address    public vow;  // receives the DAI raised
    address    public dog;  // the only caller allowed to kick

    uint256 public buf;  // starting-price multiplier [WAD] (>1e18 => start above market)
    uint256 public tip;  // flat keeper incentive       [WAD DAI]
    uint256 public chip; // proportional keeper incentive [WAD fraction of tab]

    uint256 public kicks; // auction id counter

    struct Sale {
        uint256 tab; // DAI still to raise           [WAD]
        uint256 lot; // collateral still for sale     [WAD]
        address usr; // liquidated vault owner
        uint96  tic; // auction start timestamp
        uint256 top; // starting price                [WAD]
    }
    mapping(uint256 => Sale) public sales;

    address public owner;
    modifier auth() { require(msg.sender == owner, "Clipper/not-authorized"); _; }

    event Kick(uint256 indexed id, uint256 top, uint256 tab, uint256 lot, address indexed usr, address indexed kpr, uint256 coin);
    event Take(uint256 indexed id, uint256 price, uint256 owe, uint256 slice, uint256 tabLeft, uint256 lotLeft, address indexed who);

    constructor(address vat_, address spotter_, bytes32 ilk_) {
        vat     = VatLike(vat_);
        spotter = SpotterLike(spotter_);
        ilk     = ilk_;
        owner   = msg.sender;
        buf     = WAD; // default 1.0x
    }

    function file(bytes32 what, uint256 data) external auth {
        if      (what == "buf")  buf  = data;
        else if (what == "tip")  tip  = data;
        else if (what == "chip") chip = data;
        else revert("Clipper/file-unrecognized");
    }
    function file(bytes32 what, address data) external auth {
        if      (what == "calc") calc = AbacusLike(data);
        else if (what == "vow")  vow  = data;
        else if (what == "dog")  dog  = data;
        else revert("Clipper/file-unrecognized-addr");
    }

    /// @notice The raw market price used to anchor the auction start.
    function getFeedPrice() public view returns (uint256) {
        return PipLike(spotter.pip()).read();
    }

    /// @notice Open a Dutch auction for a seized vault. Called by Dog.bark.
    ///         Starts at `top = market price * buf` (ABOVE market) and pays the
    ///         triggering keeper `kpr` the incentive `tip + chip*tab`.
    function kick(uint256 tab, uint256 lot, address usr, address kpr)
        external returns (uint256 id)
    {
        require(msg.sender == dog, "Clipper/not-dog");
        require(tab > 0 && lot > 0, "Clipper/zero");

        id = ++kicks;
        uint256 feed = getFeedPrice();
        require(feed > 0, "Clipper/zero-feed");
        uint256 top_ = feed * buf / WAD; // wmul: start the auction above market

        sales[id] = Sale({ tab: tab, lot: lot, usr: usr, tic: uint96(block.timestamp), top: top_ });

        uint256 coin;
        if (tip > 0 || chip > 0) {
            coin = tip + (tab * chip / WAD);
            vat.suck(vow, kpr, coin); // mint the keeper's incentive
        }
        emit Kick(id, top_, tab, lot, usr, kpr, coin);
    }

    /// @notice Buy collateral from a running auction at the CURRENT decayed
    ///         price. `max` is the keeper's slippage guard (max price willing
    ///         to pay). The keeper receives collateral and pays DAI to the Vow.
    /// @param  id  auction id
    /// @param  amt collateral the keeper wants                [WAD]
    /// @param  max highest price the keeper will accept        [WAD]
    /// @param  who address that receives collateral / pays DAI
    function take(uint256 id, uint256 amt, uint256 max, address who) external {
        Sale storage sale = sales[id];
        require(sale.usr != address(0), "Clipper/not-running");

        // current price on the decay curve
        uint256 price = calc.price(sale.top, block.timestamp - uint256(sale.tic));
        require(max >= price, "Clipper/too-expensive"); // keeper won't overpay

        uint256 lot = sale.lot;
        uint256 tab = sale.tab;

        uint256 slice = amt < lot ? amt : lot;   // min(amt, lot)
        uint256 owe   = slice * price / WAD;      // DAI owed for that slice

        if (owe > tab) {           // never collect more DAI than the debt owed
            owe   = tab;
            slice = owe * WAD / price;
        }

        tab -= owe;
        lot -= slice;

        // settle: keeper gets collateral, pays DAI to the Vow
        vat.flux(ilk, address(this), who, slice);
        vat.move(who, vow, owe);

        if (tab == 0 || lot == 0) delete sales[id]; // auction finished
        else { sale.tab = tab; sale.lot = lot; }

        emit Take(id, price, owe, slice, tab, lot, who);
    }
}
