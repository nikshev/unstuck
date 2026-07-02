// An API server with NO CORS headers — fine for same-origin, blocked cross-origin.
const http = require('http');
http.createServer((req, res) => {
  res.setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify({ ok: true, data: 'hello from the API' }));
}).listen(5001, () => console.log('API (no CORS headers) on :5001'));
