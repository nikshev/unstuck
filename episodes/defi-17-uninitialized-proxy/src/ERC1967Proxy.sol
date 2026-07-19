// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Minimal ERC1967-style proxy
/// @notice Every call is delegatecall-forwarded to the implementation, so the
///         implementation's CODE runs against THIS proxy's STORAGE and BALANCE.
///         The implementation address is kept in the standard ERC1967 slot so it
///         can never collide with the logic contract's own state variables.
/// @dev    This is deliberately tiny (no upgrade/admin logic) to keep the lab
///         focused on the uninitialized-initializer bug.
contract ERC1967Proxy {
    // bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
    bytes32 internal constant _IMPL_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(address implementation) {
        assembly {
            sstore(_IMPL_SLOT, implementation)
        }
    }

    function implementation() external view returns (address impl) {
        assembly {
            impl := sload(_IMPL_SLOT)
        }
    }

    /// @dev Forward everything to the implementation via delegatecall and bubble
    ///      up its return data / revert reason unchanged.
    fallback() external payable {
        assembly {
            let impl := sload(_IMPL_SLOT)
            calldatacopy(0, 0, calldatasize())
            let ok := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch ok
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
