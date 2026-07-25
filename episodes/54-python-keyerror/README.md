# Python KeyError — reproduced & fixed

Square-bracket lookup `d[key]` **demands** the key exists; asking for a key that isn't there raises
`KeyError: 'name'`, and the traceback points at the exact key and line. The clean fix for a value that
might be missing is `dict.get(key, default)`, which returns a fallback instead of crashing (or check
`key in d`, use `collections.defaultdict`, or wrap in `try/except KeyError`).

## Run
```
python3 broken.py   # KeyError: 'timeout'
python3 fixed.py    # timeout is 30
```
