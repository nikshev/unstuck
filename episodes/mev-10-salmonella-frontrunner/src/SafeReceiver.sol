// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ISalm {
    function balanceOf(address) external view returns (uint256);
    function transferFrom(address, address, uint256) external returns (bool);
}

/// @notice The defense a careful integrator uses: never trust the Transfer event / a naive
/// simulation. Pull the tokens, then VERIFY the real balance rose by exactly what you expected.
/// Against the honeypot, only 1% actually arrives, so this reverts instead of paying out on a lie.
contract SafeReceiver {
    function pull(ISalm token, address from, uint256 amount) external {
        uint256 before = token.balanceOf(address(this));
        token.transferFrom(from, address(this), amount);
        uint256 got = token.balanceOf(address(this)) - before;
        require(got == amount, "short transfer");   // <-- the event said `amount`; only `got` arrived
    }
}
