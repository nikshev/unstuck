# Dev Errors, Fixed — Ep 32: Python `RecursionError: maximum recursion depth exceeded`

🔜 **Video coming soon.** [Subscribe on YouTube](https://www.youtube.com/channel/UC32d5uV5MEC1oMqVaVbQPNA).

`RecursionError` means your function calls itself and never stops — or it's correct but simply too deep
for Python's call stack (~1000 frames).

`reproduce.py` shows the classic version: `factorial` with a base case that looks fine, `if n == 1`,
but can't be reached from every input — `factorial(0)` steps 0, -1, -2, ... away from 1 forever.

`fix.py` fixes it two ways: make the base case reachable from **every** input (`n <= 1`), and — for
genuinely deep recursion — **iterate**, since a loop has no depth limit at all.

## Run it
```bash
python3 reproduce.py   # RecursionError: maximum recursion depth exceeded
python3 fix.py         # 0! = 1 · 5! = 120 · 1400! has 3799 digits
```

The traceback's `[Previous line repeated 996 more times]` is the fingerprint of runaway recursion.
