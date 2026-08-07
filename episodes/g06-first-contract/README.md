# g06 — Your First Smart Contract (Solidity + Foundry)

Companion code for two 0xUnstuck videos:
- **g05 — What Is a Smart Contract? (I Deploy One Live)**
- **g06 — Solidity: Your First Smart Contract**

`Counter` is a ~12-line contract: it stores one number on-chain and exposes `increment()`.
It teaches the entire smart-contract loop in miniature — **write → compile → deploy → call → read.**

```solidity
contract Counter {
    uint256 public count;               // stored on-chain, readable by anyone
    event Incremented(uint256 newCount);
    function increment() external {     // the only way to change state
        count += 1;
        emit Incremented(count);
    }
}
```

## Run it yourself

```bash
./reproduce.sh
```

It compiles the contract, runs the tests, then spins up a local **Anvil** chain and
**deploys → increments → reads** it live — the exact steps shown in the video.
Requires [Foundry](https://getfoundry.sh) (`forge`, `cast`, `anvil`). No funds or keys of your own needed.

## The same contract on a real network

Deployed and **source-verified** on the public **Sepolia** testnet, readable by anyone:

`0x7036A0920A58B033363E024bCBf76A87060eBebE`
https://sepolia.etherscan.io/address/0x7036A0920A58B033363E024bCBf76A87060eBebE#code

## Files
- `src/Counter.sol` — the contract
- `test/Counter.t.sol` — Foundry tests (starts at 0, increments, emits the event)
- `reproduce.sh` — compile → test → live deploy/call on a local Anvil
