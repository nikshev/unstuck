# Python json.JSONDecodeError — reproduced & fixed
JSON is stricter than a Python dict (no trailing commas, keys in double quotes). `json.loads` on a
trailing-comma object raises `JSONDecodeError: Expecting property name enclosed in double quotes`. Fix:
wrap in `try/except json.JSONDecodeError` (use `e.lineno`, `e.colno`, `e.msg`) and fall back / validate.
## Run
```
python3 broken.py   # JSONDecodeError (trailing comma)
python3 fixed.py    # bad JSON at line 4 col 1: ...  -> port is 8080
```
