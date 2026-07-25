# defi21 — tx.origin Phishing (authorization bypass)

A wallet guards spending with `require(tx.origin == owner)`. `tx.origin` is the **human who started
the transaction**, not the immediate caller — so if the owner is tricked into calling a malicious
middle contract, that contract can spend the wallet (tx.origin is still the owner all the way down).

**Fix:** authenticate the immediate caller — `require(msg.sender == owner)`. A middle contract can't fake `msg.sender`.

## Reproduce
```
./reproduce.sh
```
- `forge test -vv` — ACT 1 honest (wallet 10→7 ETH), ACT 2 attack (wallet 10→0, attacker +10), ACT 3 fix (phish reverts "not owner").
- Live Anvil phish: deploy Wallet (0.02 ETH) + Attack, owner clicks `claimAirdrop()`; the internal
  call trace shows `Wallet::transferTo → attacker.fallback{value: 2e16}` = the whole wallet drained.

Files: `Wallet.sol` (vulnerable, tx.origin), `SafeWallet.sol` (fixed, msg.sender), `Attack.sol` (the phishing contract), `Phish.t.sol` (the 3-act test).
