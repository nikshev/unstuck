# Anatomy of the $190M Nomad Bridge Hack (rebuilt in Foundry)

A faithful, teaching-sized reproduction of the flaw that drained the **Nomad token
bridge of ~$190M in August 2022** — the "copy-paste" hack that **hundreds of ordinary
people** joined just by copying one transaction and swapping the recipient address.

## The bug in one sentence

A routine upgrade left the **zero Merkle root** (`0x00…0`) marked as an *acceptable*
root. Any withdrawal message that was **never proven** carries that zero root by
default — so the single check guarding every payout (`acceptableRoot(root)`) returned
`true` for fabricated withdrawals. No proof, no stolen key, no broken cryptography.

```solidity
// src/NomadBridge.sol — the fatal line the upgrade left behind
confirmAt[bytes32(0)] = 1;            // a zero root is "acceptable since time 1"

// src/NomadBridgeFixed.sol — the one-line fix
function acceptableRoot(bytes32 root) public view returns (bool) {
    if (root == bytes32(0)) return false;   // <-- THE ONLY CHANGE
    uint256 t = confirmAt[root];
    return t != 0 && block.timestamp >= t;
}
```

## Run it

```bash
./reproduce.sh          # or: forge test -vv
```

Expected:

```
[PASS] test_Act1_HonestWithdrawal   alice 100,000 · pool 1,000,000 -> 900,000
[PASS] test_Act2_ReplayDrain        eve 600,000 (no proof) + bob 400,000 (copy) · pool -> 0
[PASS] test_Act3_FixReverts         unproven drain reverts 'not proven'; honest still works
```

## Files

| File | Role |
|------|------|
| `src/NomadBridge.sol` | the vulnerable bridge (zero root accepted) |
| `src/NomadBridgeFixed.sol` | identical + the one-line guard |
| `src/MockToken.sol` | minimal ERC-20 that emits `Transfer` (so payouts show as a token flow on an explorer) |
| `test/Nomad.t.sol` | the three acts |

## The real hack

- **Nomad Bridge Exploiter 1** — `0x56D8B635A7C88Fd1104D23d632AF40c1C3Aac4e3` (labelled on Etherscan)
- Nomad Bridge, 2022-08-01, ~$190M drained across **300+ copycat addresses**.

This is a faithful reproduction of the **mechanism** (an unproven message passing the
root check), simplified for teaching. Part of the *Crypto & Hacks, Explained* series.
