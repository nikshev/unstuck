# 29 — ModuleNotFoundError: No module named 'X' (Python)

## 🎬 Watch

🎬 **[▶ Watch on YouTube](https://youtu.be/UsbyxozkICc)** — live now.

> The most common Python beginner error — and it almost never means the module is broken. It means
> Python looked for it on its path (`sys.path`) and didn't find it. Reproduce it, read it, fix it.

## Reproduce it ([`app.py`](app.py))
```python
import requests  # a third-party package (might not be installed here)

def get(url: str) -> int:
    resp = requests.get(url)   # send an HTTP GET request to the URL
    return resp.status_code    # hand back the numeric status (200, 404, ...)

print(get("https://example.com"))
```

```bash
python3 app.py
# Traceback (most recent call last):
#   File "app.py", line 1, in <module>
#     import requests
# ModuleNotFoundError: No module named 'requests'
```

## The 4 causes → fixes
1. **Not installed** → `pip install requests`
2. **Wrong name** → it's `requests`, not `request`
3. **Wrong environment** → you installed into a different Python/venv; check `which python` and `pip list`
4. **A local file shadows it** → a `requests.py` in your folder hides the real package → rename your file

## Fix (cause #1)
```bash
pip install requests
python3 app.py    # -> 200
```

Read the **last line** of the traceback: it names the exact module Python couldn't find. That name
is what you install, spell-check, or rename.

## Sources
- Python import system: https://docs.python.org/3/reference/import.html
- pip: https://pip.pypa.io

---
*Educational. Part of the [0xUnstuck](https://github.com/nikshev/unstuck) Dev Errors, Fixed series.*
