// Minimal static file server — only used for previewing index.html locally.
const http = require('http');
const fs = require('fs');
const path = require('path');
const ROOT = path.join(__dirname, 'www');
const PORT = 4173;
const TYPES = { '.html':'text/html', '.js':'text/javascript', '.css':'text/css' };
http.createServer((req, res) => {
  let p = decodeURIComponent(req.url.split('?')[0]);
  if (p === '/' ) p = '/index.html';
  const file = path.join(ROOT, p);
  if (!file.startsWith(ROOT) || !fs.existsSync(file)) { res.writeHead(404); res.end('not found'); return; }
  res.writeHead(200, { 'Content-Type': TYPES[path.extname(file)] || 'application/octet-stream' });
  fs.createReadStream(file).pipe(res);
}).listen(PORT, () => console.log('serving on http://localhost:' + PORT));
