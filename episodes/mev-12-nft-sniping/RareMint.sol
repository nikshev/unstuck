// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// A tiny NFT with a scarce public mint. Whoever's tx is ORDERED first in the
// block gets the rare token — ordering is set by priority gas, so a bot that
// pays more lands ahead of a normal user in the same block.
contract RareMint {
    uint256 public constant MAX = 1;                 // one rare token, FCFS
    uint256 public totalSupply;
    mapping(uint256 => address) public ownerOf;
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function mint() external returns (uint256 id) {
        require(totalSupply < MAX, "sold out");      // the loser sees this
        id = totalSupply++;
        ownerOf[id] = msg.sender;
        emit Transfer(address(0), msg.sender, id);   // real ERC-721 mint event
    }
}
