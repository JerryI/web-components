(() => {
  const protocol = location.protocol === 'https:' ? 'wss' : 'ws';
  const socket = new WebSocket(protocol + '://' + location.host);
  socket.addEventListener('message', (ev) => {
    try {
      const data = JSON.parse(ev.data);
      if (data.type === 'reload') location.reload();
    } catch (e) {}
  });
  socket.addEventListener('open', () => {
    console.debug('Live-reload connected');
  });
})();
