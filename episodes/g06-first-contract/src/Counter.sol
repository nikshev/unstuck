// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// Your first smart contract: a public counter that lives on-chain.
/// Anyone can read `count`, and anyone can call `increment()` to bump it by one.
/// Once deployed, this code runs forever, exactly as written — no server, no owner.
contract Counter {
    uint256 public count;               // stored on-chain, readable by anyone

    event Incremented(uint256 newCount);

    function increment() external {     // the only way to change state
        count += 1;
        emit Incremented(count);
    }
}
