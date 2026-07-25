// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Seller mistakenly lists a 5-ETH item for 1 ETH. It sits in the public
// mempool; the first buyer to land wins. A sniper outbids on gas, not price.
contract Market {
    address public seller;
    uint256 public price;
    bool public sold;
    address public buyer;
    event Bought(address indexed buyer, uint256 price);

    constructor(uint256 _price) { seller = msg.sender; price = _price; }

    function buy() external payable {
        require(!sold, "already sold");
        require(msg.value >= price, "underpaid");
        sold = true;
        buyer = msg.sender;
        emit Bought(msg.sender, msg.value);
    }
}
