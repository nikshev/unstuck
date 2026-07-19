// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title VaultFixed (PATCHED logic)
/// @notice Same vault, but `initialize()` is now a one-shot function guarded by a
///         hand-rolled `initializer` modifier. Combined with initializing the
///         proxy ATOMICALLY at deploy time (see the test's setUp/flow), the owner
///         slot is claimed by the deployer before anyone else can touch it, and
///         every later call to initialize() reverts.
/// @dev    Real projects use OpenZeppelin's `Initializable`: `initializer` /
///         `reinitializer` modifiers, plus `_disableInitializers()` in the LOGIC
///         contract's constructor so the implementation itself can never be
///         initialized directly. The `require(!_initialized)` below is the minimal
///         equivalent of that one-shot guard.
contract VaultFixed {
    /// @dev Slot 0 (bytes 0..19): the owner. Lives in the PROXY's storage.
    address public owner;
    /// @dev Slot 0 (byte 20): one-shot flag, packed right after `owner`.
    bool private _initialized;

    event Initialized(address indexed owner);
    event Deposited(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);

    /// @notice One-shot guard: the first successful call flips the flag; every
    ///         later call reverts. This is what the vulnerable Vault was missing.
    modifier initializer() {
        require(!_initialized, "already initialized");
        _initialized = true;
        _;
    }

    function initialize(address _owner) external initializer {
        owner = _owner;
        emit Initialized(_owner);
    }

    function deposit() external payable {
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw() external {
        require(msg.sender == owner, "not owner");
        uint256 bal = address(this).balance;
        (bool ok, ) = payable(owner).call{value: bal}("");
        require(ok, "transfer failed");
        emit Withdrawn(owner, bal);
    }
}
