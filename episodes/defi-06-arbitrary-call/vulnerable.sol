// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ❌ VULNERABLE — the router forwards ANY call the caller supplies,
//    executed with the ROUTER itself as msg.sender.
contract RouterVulnerable {
    function execute(address target, bytes calldata data) external returns (bytes memory) {
        (bool ok, bytes memory ret) = target.call(data);   // arbitrary call, as the router
        require(ok, "call failed");
        return ret;
    }
}
