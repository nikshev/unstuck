# 22 — Fix "X is not a function" (JavaScript)

> The part after the dot is what's `undefined`. Read it literally, then check the usual suspects.

📺 Video: _(soon)_

## Reproduce ([`reproduce.js`](reproduce.js))
```
1) TypeError: numbers.foreach is not a function   // typo: forEach (capital E)
2) TypeError: api.getuser is not a function        // wrong casing: getUser
```

## Diagnose + fix ([`fix.js`](fix.js))
```js
console.log(typeof numbers.forEach); // 'function' = good, 'undefined' = your bug
numbers.forEach(n => ...);           // right name, right casing
```

## Usual suspects
Typo/casing · value is `undefined`/`null` · **default vs named import mismatch** · it's genuinely not a function · shadowed variable.

## Run
```bash
node reproduce.js   # throws the TypeErrors
node fix.js         # typeof checks + correct calls
```
