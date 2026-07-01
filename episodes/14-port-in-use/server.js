const http = require('http');
http.createServer((_, res) => res.end('hi'))
    .listen(3000, () => console.log('a server is now holding port 3000...'));
