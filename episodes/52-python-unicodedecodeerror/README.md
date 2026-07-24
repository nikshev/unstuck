# ep44 — Python UnicodeDecodeError

A text file is just **bytes**; an **encoding** maps them to characters. `open()` in text mode defaults to
UTF-8, but this file was saved as Latin-1, so the byte `0xE9` (\"é\") is not valid UTF-8:

```
UnicodeDecodeError: 'utf-8' codec can't decode byte 0xe9 in position 8: invalid continuation byte
```

```bash
python3 broken.py    # UnicodeDecodeError
python3 fixed.py     # works -> name=café / price=5
```

**Fix:** `open(..., encoding=\"latin-1\")` — name the real encoding. Or `errors=\"replace\"` to never
crash; or open in binary and decode explicitly.
