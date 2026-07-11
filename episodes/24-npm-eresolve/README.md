# Fix npm ERESOLVE Peer Dependency Errors

## 🎬 Watch

[![Watch on YouTube](https://img.youtube.com/vi/vBKKuD3gdQA/maxresdefault.jpg)](https://youtu.be/vBKKuD3gdQA)

▶️ **Watch: https://youtu.be/vBKKuD3gdQA**


📺 Video: **Fix npm "ERESOLVE" Peer Dependency Errors**

`npm install` fails with `ERESOLVE unable to resolve dependency tree`. It just means two packages
disagree about a version. Read the two lines it prints:

```
Found: react@18.2.0
peer react@"^16.8.0 || ^17.0.0" from @material-ui/core@4.12.4
```

Your project **has** react 18; `@material-ui/core@4` **needs** react 16 or 17. `18` isn't in that
range → conflict.

## Reproduce ([`broken/package.json`](broken/package.json))
```bash
cd broken && npm install      # -> ERESOLVE
```

## Fix ([`fixed/package.json`](fixed/package.json))
Make the versions agree. Here react is pinned to 17 (what MUI v4 asks for); in practice you'd usually
**upgrade the old package** (MUI v4 → v5) to support react 18.
```bash
cd fixed && npm install       # -> added 42 packages
```

## Three ways out
1. **Align versions** (best) — upgrade the outdated package, or match what it needs.
2. **`overrides`** in package.json — force one version (use with care).
3. **`npm install --legacy-peer-deps`** — ignore peer checks (last resort; may ship a broken combo).
