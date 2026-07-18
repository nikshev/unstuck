# Dev Errors, Fixed — Ep 36: Python TypeError (int + str)

## 🎬 Watch

🔴 **New episode** — [Subscribe](https://www.youtube.com/channel/UC32d5uV5MEC1oMqVaVbQPNA?sub_confirmation=1) to catch it when it drops.

`TypeError: unsupported operand type(s) for +: 'int' and 'str'`. The `+` operator **adds** numbers and
**joins** strings — so when one side is a number and the other is text, Python refuses to guess and stops.
It bites constantly because values from `input()`, JSON, CSV, and web forms all arrive as **strings**, and
they look fine right up until you add one to a real number.

## Reproduce & fix

- **`app.py`** — sums a list where one value snuck in as text (`[10, 5, "3", 2]`). `total = total + p`
  works until `p == "3"`, then **int + str → TypeError**.
- **`app_fixed.py`** — convert **at the boundary**: `total = total + int(p)` for the arithmetic, and for the
  other direction (building a message) `"items: " + str(count)` or an f-string `f"items: {count}"`. Best of
  all, parse to the right type as early as possible.

## Run it yourself

Requires Python 3.

```bash
python3 app.py         # reproduces the TypeError (int + str)
python3 app_fixed.py   # runs clean
```

`app_fixed.py` prints:

```
total: 20
items: 3
items: 3
```

> The rule to remember: `+` means *add* for numbers and *join* for strings — pick one by converting at the
> boundary (`int()`/`float()` for math, `str()` or an f-string for text) before the two ever meet.
