# 10 — Fix "Cannot read properties of undefined" (JavaScript)

## 🎬 Watch

[![Watch on YouTube](https://img.youtube.com/vi/4KeWfekcK4k/maxresdefault.jpg)](https://youtu.be/4KeWfekcK4k)

▶️ **Watch: https://youtu.be/4KeWfekcK4k**


> The most common JS runtime error — what it means and how to fix it.

📺 Video: _(soon)_

## Reproduce ([`reproduce.js`](reproduce.js))
`user.address` is `undefined`, and reading `.city` **of undefined** throws:
```
TypeError: Cannot read properties of undefined (reading 'city')
```
The `(reading 'city')` part names the property, so the thing before `.city` is what was undefined.

## Fix ([`fix.js`](fix.js))
```js
const city = user.address?.city ?? "unknown";  // optional chaining + fallback
```
Other fixes: a guard (`if (user.address)`), destructuring defaults, or validating data at the boundary.
Don't `?.` everything blindly — if a field SHOULD exist, fix the source.

## Run
```bash
node reproduce.js   # throws TypeError
node fix.js         # City: unknown
```
