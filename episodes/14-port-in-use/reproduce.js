const http = require('http');

// Server A grabs port 3000
const a = http.createServer().listen(3000, () =>
  console.log('Server A is listening on port 3000'));

// Server B tries the SAME port — only one process can own a port
const b = http.createServer();
b.on('error', (e) => {
  console.error('FAILED:', e.code, '-', e.message);
  a.close();
  process.exit(0);
});
b.listen(3000);
