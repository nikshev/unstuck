"""
Vanity address grinder — EDUCATIONAL DEMO
=========================================
Shows HOW a "look-alike" address is made: guess a key pair, derive the address,
check ONLY the characters a human actually looks at, throw it away, repeat.

⚠️  This grinds a vanity address for YOURSELF (the legitimate use, like 0xC0FFEE...).
    Making one that mimics SOMEONE ELSE'S address to trick them into sending funds is
    theft — never do it. The point is to see WHY the ends are cheap to fake and the
    middle never can be, so you know to check the middle.

Google Colab:  !pip install eth-account    then paste this file and run.
"""
import time
from eth_account import Account

def grind(prefix: str, budget_s: float = 30.0):
    target, tried, t0 = prefix.lower(), 0, time.time()
    while time.time() - t0 < budget_s:
        addr = Account.create().address          # 1+2. random key -> address
        tried += 1
        if addr[2:2 + len(target)].lower() == target:   # 3. compare ONLY the start
            return addr, tried, time.time() - t0
        # 4. no match -> discard, loop
    return None, tried, time.time() - t0

if __name__ == "__main__":
    print("Each extra hex character = 16x more work.\n")
    rate = None
    for p in ("a", "ab", "abc"):
        addr, tried, secs = grind(p, 30)
        rate = tried / secs
        if addr:
            print(f"  0x{p:<4} FOUND  {addr}")
            print(f"        {tried:>8,} tries · {secs:5.2f}s")
        else:
            print(f"  0x{p:<4} not found in {secs:.0f}s ({tried:,} tries)")
    print(f"\n  this laptop, pure Python: ~{rate:,.0f} addresses/sec\n")
    print("  extrapolating the SAME loop:")
    for n in (4, 6, 8, 10, 40):
        need = 16 ** n
        secs = need / rate
        if   secs < 60:      human = f"{secs:.0f} seconds"
        elif secs < 3600:    human = f"{secs/60:.0f} minutes"
        elif secs < 86400:   human = f"{secs/3600:.0f} hours"
        elif secs < 3.15e7:  human = f"{secs/86400:.0f} days"
        else:                human = f"{secs/3.15e7:.3g} years"
        label = f"{n} chars" + (" (the WHOLE address)" if n == 40 else "")
        print(f"    {label:<28} ~{need:.2e} tries   ->  {human}")
    print("\n  A GPU rig does this ~millions of times faster — which moves the")
    print("  first few / last few characters into 'seconds', and moves the FULL")
    print("  address absolutely nowhere. That's why the middle is always genuine.")
