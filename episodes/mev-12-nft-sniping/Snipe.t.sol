// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/RareMint.sol";
import "../src/Market.sol";

// A forge test executes txs in the ORDER we call them — exactly like a block
// whose order was already decided. So we make the ORDER the variable and show:
// same two txs, whoever is placed first wins. In a real block that placement
// is bought with priority gas (demonstrated live on Anvil — see mempool.sh).
contract SnipeTest is Test {
    address user   = makeAddr("user");     // submitted first, pays normal gas
    address sniper = makeAddr("sniper");   // submitted later, pays MORE gas

    // MINT SNIPING: sniper's mint is ordered ahead of the user's -> sniper
    // gets the only token, the user's mint reverts "sold out".
    function test_mint_sniper_wins() public {
        RareMint nft = new RareMint();

        vm.prank(sniper);                  // ordered FIRST (higher priority fee)
        uint256 id = nft.mint();
        console.log("sniper minted token id:", id);
        console.log("owner of #0 is sniper?:", nft.ownerOf(0) == sniper);

        vm.prank(user);                    // ordered SECOND -> nothing left
        vm.expectRevert(bytes("sold out"));
        nft.mint();
        console.log("user's mint reverted: sold out");
        assertEq(nft.ownerOf(0), sniper);
    }

    // Control: it is ONLY the ordering. Put the user first and the user wins.
    function test_mint_ordering_is_everything() public {
        RareMint nft = new RareMint();
        vm.prank(user);
        nft.mint();
        assertEq(nft.ownerOf(0), user);
        console.log("user first -> user owns #0 (proves it's pure ordering)");
    }

    // LISTING SNIPING: a 5-ETH item mis-listed at 1 ETH. Sniper's buy is
    // ordered first -> grabs it; the honest buyer's buy reverts.
    function test_listing_snipe() public {
        Market m = new Market(1 ether);
        vm.deal(sniper, 1 ether);
        vm.deal(user, 1 ether);

        vm.prank(sniper);                  // ordered first
        m.buy{value: 1 ether}();
        console.log("sniper bought the mispriced item");

        vm.prank(user);
        vm.expectRevert(bytes("already sold"));
        m.buy{value: 1 ether}();
        console.log("honest buyer reverted: already sold");
        assertEq(m.buyer(), sniper);
    }
}
