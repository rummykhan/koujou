import { createServer } from '../src/server.js';

// Starts a server on a free port; returns { url, close }.
export async function start(deps) {
  const server = createServer(deps);
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const { port } = server.address();
  return { url: `http://127.0.0.1:${port}`, close: () => new Promise((resolve) => server.close(resolve)) };
}
