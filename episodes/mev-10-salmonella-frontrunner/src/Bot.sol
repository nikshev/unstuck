// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
interface IToken {
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
}

/// @notice A generalized front-runner. It watches the mempool, sees a "profitable" token move,
/// and blindly COPIES it -- forwarding the same amount it saw. It trusts the token. Because it is
/// NOT the honeypot owner, its transfer really moves only 1%, while the event still reports the
/// full amount. The bot spent gas and capital chasing a number that was never real.
contract Bot {
    function run(address token, address to, uint256 amount) external {
        IToken(token).transfer(to, amount);
    }
    function approveSpender(address token, address spender) external {
        IToken(token).approve(spender, type(uint256).max);
    }
}
