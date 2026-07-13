# 34 — Fix Python IndexError: list index out of range

## 🎬 Watch

🔜 **Video coming soon.** [Subscribe on YouTube](https://www.youtube.com/channel/UC32d5uV5MEC1oMqVaVbQPNA) to catch it.

> A list of length `n` has indexes `0 … n-1`. Reach for one past the end and Python stops with
> `IndexError: list index out of range`. Almost always an off-by-one.

## Reproduce ([`reproduce.py`](reproduce.py))
```python
nums = [10, 20, 30]
def print_all(items):
    for i in range(len(items) + 1):  # BUG: + 1 walks one PAST the end
        print(items[i])              # items[3] doesn't exist -> IndexError
print_all(nums)
```
```
$ python3 reproduce.py
10
20
30
IndexError: list index out of range
```
It prints all three real items, then fails on the fourth step — the one past the end.

## Causes → fixes
1. **Off-by-one** → `range(len(x))`, no `+ 1`
2. **Don't index at all** → `for item in x:` (can never go out of range)
3. **Empty list** → `x[0]` on `[]` fails; check `len(x)` first
4. **Hardcoded index too big** → guard with `len(x)`

## Fix ([`fix.py`](fix.py))
```python
def print_all(items):
    for item in items:   # iterate the items directly — no index math
        print(item)
```
```
$ python3 fix.py
10
20
30
```

## Sources
- Python sequences & indexing: https://docs.python.org/3/tutorial/introduction.html#lists

---
*Part of the [0xUnstuck](https://github.com/nikshev/unstuck) Dev Errors, Fixed series.*
