# ep42 — Python circular import

Two modules import each other at load time, so one runs while the other is still half-initialized:
`ImportError: cannot import name ... from partially initialized module (most likely due to a circular import)`.

```bash
cd broken && python3 main.py     # ImportError (circular)
cd ../fixed && python3 main.py   # works: helper_a -> helper_b uses [hello from a]
```

**Fix:** move the import *inside* the function that needs it (a deferred / lazy import), so it runs only
after both modules finish loading. Bigger picture: pull the shared name into a third module both import.
