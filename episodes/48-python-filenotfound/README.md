# Dev Errors, Fixed — Ep 40: Python FileNotFoundError (No such file or directory)

## 🎬 Watch

🔴 **New episode** — [Subscribe](https://www.youtube.com/channel/UC32d5uV5MEC1oMqVaVbQPNA?sub_confirmation=1) to catch it when it drops.

`FileNotFoundError: [Errno 2] No such file or directory: 'config.txt'`. Python went to the path you gave
it and found nothing. The trap: a **bare relative name** like `"config.txt"` is completed against the
**current working directory** — the folder you launched `python` from — **not** the folder your script
lives in. So the same line works from one folder and crashes from another, on a server, or in Docker. The
file never moved; your starting point did. The quoted value at the end of the error is exactly what Python
tried to open — a bare name means it was resolved against the wrong folder.

## Reproduce & fix

- **`reproduce.py`** — `open("config.txt")` while the file actually lives in `data/config.txt` → looks in
  the current working directory, finds nothing, **FileNotFoundError**.
- **`fix.py`** — anchor the path to the script itself with `Path(__file__).parent / "data" / "config.txt"`
  (correct no matter where you launch `python`), then wrap the read in `try / except FileNotFoundError` so a
  genuinely missing file falls back to defaults instead of crashing.

## Run it yourself

Requires Python 3.

```bash
python3 reproduce.py   # FileNotFoundError: 'config.txt'
python3 fix.py         # reads data/config.txt from any folder
```

`fix.py` prints:

```
theme=dark
volume=8
```

> The rule: don't trust a bare relative name. Anchor to the script with `Path(__file__).parent`, join the
> real subfolder and filename, and handle the missing case on purpose. Read the quoted path at the end of
> the error and fix **where you're pointing**, not the file.
