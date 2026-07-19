// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Vault (VULNERABLE logic)
/// @notice Upgradeable-style vault logic meant to sit behind an ERC1967 proxy.
///         `initialize()` is supposed to run exactly once, at deploy time, to set
///         the owner. Here it is BROKEN in two ways that together let anyone take
///         over the live proxy:
///           1. There is NO one-shot guard, so it can be called again and again.
///           2. It is NOT called atomically at deploy (it is a separate, public,
///              front-runnable transaction), so on a freshly deployed proxy the
///              owner is still address(0) and up for grabs.
contract Vault {
    /// @dev Slot 0. Because calls arrive via delegatecall, this lives in the
    ///      PROXY's storage, not the logic contract's.
    address public owner;

    event Initialized(address indexed owner);
    event Deposited(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);

    /// @notice THE BUG: no `initializer` guard and no access control.
    ///         Anyone can call this on the proxy and become the owner.
    function initialize(address _owner) external {
        owner = _owner;
        emit Initialized(_owner);
    }

    /// @notice Anyone can deposit ETH into the vault.
    function deposit() external payable {
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice "Owner only" — sends the entire balance to the owner.
    ///         Harmless on its own; catastrophic once ownership can be hijacked.
    function withdraw() external {
        require(msg.sender == owner, "not owner");
        uint256 bal = address(this).balance;
        (bool ok, ) = payable(owner).call{value: bal}("");
        require(ok, "transfer failed");
        emit Withdrawn(owner, bal);
    }
}
