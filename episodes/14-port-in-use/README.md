# 14 — Fix "Port 3000 already in use" (EADDRINUSE)

> Only one process can own a port. Free it, or run on another.

📺 Video: _(soon)_

## Reproduce ([`reproduce.js`](reproduce.js))
Two servers try the same port; the second fails:
```
FAILED: EADDRINUSE - listen EADDRINUSE: address already in use :::3000
```

## Fix (macOS / Linux)
```bash
lsof -i :3000            # find the PID holding the port
kill $(lsof -t -i:3000)  # free it   (kill -9 if stubborn)
# or just use another port:
PORT=3001 npm start
```
Windows: `netstat -ano | findstr :3000` → `taskkill /PID <pid> /F`.

## Run
```bash
node reproduce.js   # triggers EADDRINUSE
node server.js      # a plain server on :3000 (Ctrl+C to stop)
```
