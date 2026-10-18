# g43 — the on-chain lab

The off-chain decoder (`../decode_permit.py`) shows **what** you are signing. This shows **what it
does**, as real transactions on a real chain.

> ⚠️ Lab only. The token is ours, the "victim" key is a well-known test key, and the collector can
> only move tokens that the holder has already permitted. There is no exploit here and nothing that
> works against anyone else: a real drainer's hard part is the phishing site, and none of that is
> here.

## Run the proof (no RPC, no key, no network)

```bash
forge test -vv
```

```
--- the victim has now signed the message ---
allowance on-chain           : 0
token nonce for victim       : 0
victim balance               : 10000 LUSD

--- 11 days later, the attacker redeems the signature ---
victim balance               : 0 LUSD
attacker balance             : 10000 LUSD
token nonce for victim       : 1 <- consumed, by the ATTACKER's tx
```

**The checkable difference**, asserted in the tests:

| | allowance written on-chain | visible to a wallet | revocable |
|---|---|---|---|
| `permit` signature | **0** | no | **nothing to revoke** |
| `approve()` transaction | unlimited | yes | yes |

A permit creates **no on-chain state** until it is spent. That is precisely why the victim sees
nothing happen and closes the tab.

⚠️ **A note on how this is proven.** An earlier version asserted `vm.getNonce(victim) == 0` to show
"the victim never sent a transaction". It passed — *vacuously*: `vm.prank` changes `msg.sender`
without bumping a nonce, so the value was 0 on both paths and the assertion proved nothing. It is
replaced by assertions on on-chain state, which is the real difference.

## The public-chain capstone

```bash
export RPC=<your Sepolia RPC>
export PK=<a funded test key>
forge script script/Capstone.s.sol:Capstone --rpc-url $RPC --private-key $PK --broadcast --legacy
```

Verified end-to-end against a local Anvil (`ONCHAIN EXECUTION COMPLETE & SUCCESSFUL`); pointing it at
a public testnet is the same command with a different `--rpc-url`. It prints the token, collector and
victim addresses so every transaction can be opened on a block explorer:

1. the mint — the victim has a balance
2. **nothing** — the signature happens off-chain and leaves no transaction
3. one transaction from the attacker, carrying both the `permit` redemption and the `transferFrom`

Step 2 is the one worth pausing on: there is no transaction to show, and that is the finding.
