// Simulates what the BROWSER does: sends your frontend's Origin,
// then checks the Access-Control-Allow-Origin response header.
const http = require('http');
const ORIGIN = 'http://localhost:3000';

http.get({ host: 'localhost', port: 5001, path: '/api/data',
           headers: { Origin: ORIGIN } }, (res) => {
  const acao = res.headers['access-control-allow-origin'];
  if (acao === ORIGIN || acao === '*') {
    let body = '';
    res.on('data', c => body += c);
    res.on('end', () => {
      console.log('Access-Control-Allow-Origin:', acao);
      console.log('OK: response delivered to the page:', body);
      process.exit(0);
    });
  } else {
    console.error("Access to fetch at 'http://localhost:5001/api/data' from origin");
    console.error(`'${ORIGIN}' has been blocked by CORS policy: No`);
    console.error("'Access-Control-Allow-Origin' header is present on the requested resource.");
    process.exit(0);
  }
});
