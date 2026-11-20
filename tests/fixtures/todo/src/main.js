import { createServer } from './server.js';

const port = Number(process.env.PORT ?? 3000);
createServer().listen(port, '127.0.0.1', () => {
  console.log(`todo listening on :${port}`);
});
