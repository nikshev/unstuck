# Anatomy of the $325M Wormhole Hack — rebuilt in Foundry

Feb 2022: an attacker minted **120,000 wrapped ETH (~$325M) out of nothing** on the Wormhole bridge —
no deposit. Wormhole mints wrapped tokens when off-chain **guardians** sign a message (a VAA) attesting
to a deposit; it needed 13 of 19 signatures. The whole security is that signature check — and it
trusted the wrong thing: it verified the signatures against a guardian set **the caller supplies**,
instead of its own stored set. So the attacker signed a fake deposit with their **own** keys, passed
their own addresses in as the "guardians", and every check passed.

This is a faithful reproduction of that mechanism, in three acts.

## Files
- `Bridge.sol` — vulnerable: `receiveAndMint(..., address[] claimedGuardians, bytes[] sigs)` verifies
  sigs against **claimedGuardians (from the caller)**.
- `BridgeFixed.sol` — the fix (with a BEFORE/AFTER comment): no caller list; verify against the
  contract's own **stored `guardians`**.
- `Wormhole.t.sol` — three acts, using `vm.sign` to produce real signatures.

## Run
```bash
./reproduce.sh          # forge test -vv
```
- **Act 1 (honest):** real guardians attest a deposit → user minted 10.
- **Act 2 (attack):** attacker signs with their own keys + passes them as guardians → minted **120,000**
  wETH, no deposit.
- **Act 3 (fix):** same forged sigs vs the fixed bridge → revert `not a guardian`, minted 0.

## The real hack, on-chain
Wormhole Network Exploiter: [`0x629e7Da20197a5429d30da36E77d06CdF796b71A`](https://etherscan.io/address/0x629e7Da20197a5429d30da36E77d06CdF796b71A)
(Etherscan: Wormhole Network Exploiter · Exploit). ~$325M / 120,000 wETH. The original was a Solana/Rust
spoofed-`sysvar` bug; this reproduces the mechanism in Solidity: a signature check against attacker-controllable trust.

## The lesson
Verifying a signature is only half the job — **what you verify it against** is the other half. Never
check trust against a set the caller supplies; pin it in the contract, immutably.

> Educational reproduction. No real funds or users involved.
