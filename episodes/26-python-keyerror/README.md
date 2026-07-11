# Fix Python KeyError

📺 Video: **Fix Python KeyError the Clean Way**

`KeyError` means you asked a dict for a key it doesn't have. Read the traceback **bottom-up**: the
last line is `KeyError: 'carol'`, and just above it is the exact line that raised it.

## Reproduce ([`reproduce.py`](reproduce.py))
```bash
python3 reproduce.py    # 30, then KeyError: 'carol'
```
`return users[name]` indexes the dict directly — a missing key crashes.

## Fix ([`fix.py`](fix.py))
```bash
python3 fix.py          # 30, then 0  (no crash)
```
`users.get(name, 0)` returns a default instead of raising.

## Four ways to handle it
1. `dict.get(key, default)` — the usual, clean fix
2. `if key in dict:` — check before you index
3. `collections.defaultdict` — auto-default for missing keys
4. `try / except KeyError` — when a missing key is truly exceptional
