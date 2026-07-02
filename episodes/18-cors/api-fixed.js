// FIX: the SERVER declares who may call it, via CORS response headers.
const http = require('http');
const ALLOWED = 'http://localhost:3000'; // your frontend's origin

http.createServer((req, res) => {
  res.setHeader('Access-Control-Allow-Origin', ALLOWED);
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') { res.writeHead(204); return res.end(); } // preflight
  res.setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify({ ok: true, data: 'hello from the API' }));
}).listen(5001, () => console.log('API (CORS fixed) on :5001'));
