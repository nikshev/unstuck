#!/usr/bin/env python3
"""Read a token's Solidity source and flag the five patterns that let a team take your money.

No API key, no network: paste a verified contract's source into a file and run it. Every rule is
a pattern you can also find by eye — the point is to show you WHAT to look for, not to sell a scanner.

    python3 rug_check.py contracts/honeypot.sol
    python3 rug_check.py --demo          # run the bundled good/bad examples
"""
import re, sys, pathlib

RULES = [
    # NOTE: the test is NOT "is there a require?" — `require(msg.sender==owner)` is ACCESS
    # CONTROL, not a cap. A cap is a require that bounds the AMOUNT against a maximum.
    ("UNCAPPED MINT", "critical",
     r"function\s+mint\s*\([^)]*\)[^{]*\{(?![^}]*require\s*\([^)]*(totalSupply|MAX|CAP|maxSupply))[^}]*_mint",
     "The team can create new tokens at will. Your share can be diluted to nothing,\n"
     "     and the new supply can be dumped on the pool you are holding."),
    ("SELL BLOCK / HONEYPOT", "critical",
     r"(canSell|_isBlacklisted|tradingEnabled|_canTransfer)\s*\[?[^;]*\]?\s*(=|;)",
     "A per-address or global switch on selling. You can buy, and then find you\n"
     "     are the only one who cannot get out. This is what a honeypot is."),
    ("UNBOUNDED FEE", "critical",
     r"function\s+set\w*(Fee|Tax)\w*\s*\([^)]*\)[^{]*\{(?![^}]*require\s*\([^)]*<=)",
     "A fee the owner can change with no upper bound written into the code.\n"
     "     A 100% sell tax is a rug that does not even need to move the liquidity."),
    ("OWNER CAN PULL LIQUIDITY", "critical",
     r"(removeLiquidity|withdrawLiquidity|emergencyWithdraw)\s*\(",
     "The team can take the trading pool itself. The token still exists;\n"
     "     there is simply nothing left to sell it into."),
    ("HIDDEN UPGRADE PATH", "high",
     r"(delegatecall|_upgradeTo|upgradeToAndCall)\s*\(",
     "Today's code is not tomorrow's code. Anything audited can be replaced\n"
     "     after you buy, by whoever holds the upgrade key."),
]
GOOD = [("renounceOwnership", r"renounceOwnership\s*\("),
        ("hard-capped supply", r"require\s*\([^)]*totalSupply\(\)\s*\+[^)]*<=\s*(MAX|CAP)"),
        ("fee ceiling enforced", r"require\s*\([^)]*(fee|tax)[^)]*<=\s*\d+")]

def check(src, name):
    print(f"\n{'='*74}\n  {name}\n{'='*74}")
    hits = []
    for label, sev, pat, why in RULES:
        if re.search(pat, src, re.S | re.I):
            hits.append((label, sev)); print(f"  [{sev.upper():>8}]  {label}\n     {why}\n")
    for label, pat in GOOD:
        if re.search(pat, src, re.S | re.I):
            print(f"  [    good]  {label}")
    print(f"\n  -> {len(hits)} red flag(s)." if hits else "\n  -> no red flags in these five patterns.")
    return hits

DEMO_BAD = """
contract Token {
    address owner; mapping(address=>bool) _isBlacklisted; uint256 public sellTax;
    function mint(address to, uint256 amt) external { require(msg.sender==owner); _mint(to, amt); }
    function setSellTax(uint256 t) external { require(msg.sender==owner); sellTax = t; }
    function removeLiquidity() external { require(msg.sender==owner); /* takes the pool */ }
}"""
DEMO_GOOD = """
contract Token {
    uint256 constant MAX = 1_000_000e18; uint256 public fee;
    function mint(address to, uint256 amt) external onlyOwner {
        require(totalSupply() + amt <= MAX, "cap"); _mint(to, amt); }
    function setFee(uint256 f) external onlyOwner { require(f <= 5, "fee too high"); fee = f; }
    function renounceOwnership() public onlyOwner { _transferOwnership(address(0)); }
}"""

if __name__ == "__main__":
    if "--demo" in sys.argv or len(sys.argv) == 1:
        check(DEMO_BAD, "EXAMPLE A — a token built to be exited")
        check(DEMO_GOOD, "EXAMPLE B — the same functions, bounded")
    else:
        p = pathlib.Path(sys.argv[1]); check(p.read_text(), p.name)
