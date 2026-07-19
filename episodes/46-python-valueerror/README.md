# Dev Errors, Fixed — Ep 38: Python ValueError (int() on a decimal string)

## 🎬 Watch

🔴 **New episode** — [Subscribe](https://www.youtube.com/channel/UC32d5uV5MEC1oMqVaVbQPNA?sub_confirmation=1) to catch it when it drops.

`ValueError: invalid literal for int() with base 10: '12.5'`. `int()` parses a **whole-number** string —
hand it `"12.5"` (a decimal that arrived as text) and it refuses, because silently dropping the fraction
would be a guess. It bites constantly: values from `input()`, CSV cells, JSON, and web forms all arrive as
**strings**, and a stray decimal or space hides among them until `int()` trips over it.

## Reproduce & fix

- **`reproduce.py`** — sums `["3", "10", "12.5"]` with `total + int(q)`. Fine for `"3"` and `"10"`, then
  `int("12.5")` → **ValueError: invalid literal for int()**.
- **`fix.py`** — `.strip()` first (a stray space/newline is the #1 hidden cause), then `int(q)` on the clean
  path and **fall back to `int(float(q))`** for a decimal string (`"12.5"` → `12.5` → `12`). Even better,
  parse to the right type — `int` vs `float` — as early as the data enters.

## Run it yourself

Requires Python 3.

```bash
python3 reproduce.py   # raises ValueError on "12.5"
python3 fix.py         # runs clean
```

`fix.py` prints:

```
total: 25
```

> The rule: `int("12")` is fine, `int("12.5")` is not — `int()` won't parse a fraction. Decide `int` vs
> `float` at the boundary (and `.strip()` the text first) so a decimal or a stray space can't reach it as a
> surprise.
