# 36 — Fix Python AttributeError: 'NoneType' object has no attribute

## 🎬 Watch

🔜 **Video coming soon.** [Subscribe on YouTube](https://www.youtube.com/channel/UC32d5uV5MEC1oMqVaVbQPNA) to catch it.

> `AttributeError: 'NoneType' object has no attribute X` means the value is **None**, and you called a
> method on it. The crash line is a red herring — trace the None **up** to where it was born. The #1
> cause: a function that **forgot to `return`**.

## Reproduce ([`reproduce.py`](reproduce.py))
```python
def build_user(name, email):
    user = {"name": name, "email": email, "active": True}
    # BUG: no return -> build_user returns None

u = build_user("Ada", "ada@x.com")   # u is None
print(greet(u))                      # greet does user.get(...) on None
```
```bash
python3 reproduce.py   # AttributeError: 'NoneType' object has no attribute 'get'
```

## The fix ([`fix.py`](fix.py))
Actually return the dict:
```python
    return user
```
```bash
python3 fix.py   # Hello, Ada Lovelace
```

## Read the traceback
- The bottom line tells you **what** (`'NoneType' has no attribute 'get'`) and **where** it crashed (`greet`).
- The crash site is rarely the real bug. Ask: *where did this None come from?* and trace **up**.
- Common causes: a forgotten `return` · `list.sort()`/`.append()` return None · `dict.get()` miss · an API/DB call that returns None on "not found".
