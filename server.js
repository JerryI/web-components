const path = require('path');
const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const chokidar = require('chokidar');

const app = express();
const publicDir = path.join(__dirname, 'public');
app.use(express.static(publicDir));

const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

wss.on('connection', (ws) => {
  console.log('Live-reload client connected');
});

// Watch public directory for changes and notify clients to reload
const watcher = chokidar.watch(publicDir, { ignoreInitial: true });
watcher.on('all', (event, filePath) => {
  console.log('File change detected:', event, filePath);
  const msg = JSON.stringify({ type: 'reload' });
  wss.clients.forEach((client) => {
    if (client.readyState === WebSocket.OPEN) client.send(msg);
  });
});

const port = process.env.PORT || 3000;
server.listen(port, () => {
  console.log(`Static server running at http://localhost:${port}`);
});
