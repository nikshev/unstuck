# Dev Errors, Fixed — Ep 34: Python UnboundLocalError

## 🎬 Watch

🔔 [Subscribe on YouTube](https://www.youtube.com/channel/UC32d5uV5MEC1oMqVaVbQPNA?sub_confirmation=1) — one real dev error, reproduced and fixed at the root, every episode.

`UnboundLocalError: cannot access local variable 'x' where it is not associated with a value`. The
variable is defined at the top of your file, yet inside a function Python swears it doesn't exist. Why?
Python decides a name's scope by scanning the **whole** function before it runs: if you **assign** to a
name anywhere, that name is **local everywhere** — so a read *before* that assignment finds nothing, not
even the global with the same name.

## Reproduce & fix

- **`app.py`** — a module-level `count = 0` and a function that does `count += 1` (a read *and* a write).
  The write makes `count` local for the whole function, so the read on that same line has no value yet →
  **UnboundLocalError**.
- **`app_fixed.py`** — two fixes: **(1)** `global count` (or `nonlocal` for an enclosing function's
  variable), and **(2)**, the cleaner one: don't mutate a global at all — take the value in as an argument
  and return the new one.

## Run it yourself

Requires Python 3.

```bash
python3 app.py         # reproduces the UnboundLocalError
python3 app_fixed.py   # runs clean
```

> The rule to remember: an assignment doesn't just set a variable — it decides, for the whole function,
> which variable you even mean.
