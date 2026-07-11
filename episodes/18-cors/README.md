# 18 — Fix the CORS Error (the right way)

## 🎬 Watch

[![Watch on YouTube](https://img.youtube.com/vi/3vpaV1tyQ3s/maxresdefault.jpg)](https://youtu.be/3vpaV1tyQ3s)

▶️ **Watch: https://youtu.be/3vpaV1tyQ3s**


> "Blocked by CORS policy" — the BROWSER hides cross-origin responses until the SERVER
> allows your origin. curl/Postman work because they aren't browsers.

📺 Video: _(soon)_

## Reproduce
[`api.js`](api.js) sends no CORS headers; [`browser-sim.js`](browser-sim.js) does what a browser
does (sends `Origin`, checks `Access-Control-Allow-Origin`) and prints the classic console error.
```bash
sh run-broken.sh   # -> blocked by CORS policy: No 'Access-Control-Allow-Origin' ...
```

## Fix — on the server ([`api-fixed.js`](api-fixed.js))
```js
res.setHeader('Access-Control-Allow-Origin', 'http://localhost:3000');
res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
if (req.method === 'OPTIONS') { res.writeHead(204); return res.end(); } // preflight
```
```bash
sh run-fixed.sh    # -> OK: response delivered to the page
```

## Don'ts
Disable-CORS extensions and `--disable-web-security` only mask it on YOUR machine;
`*` with credentials is rejected by browsers. In real apps: Express `cors` middleware,
Rust `tower-http` CorsLayer, or a dev-server proxy.
