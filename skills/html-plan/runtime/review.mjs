#!/usr/bin/env node
// Serve one packed plan until its response is saved and acknowledged.
// stderr: review URL and errors. stdout: exact response Markdown on success.
// IO contract: ../references/review-io.md
import { randomBytes } from 'node:crypto';
import { readFileSync, statSync, writeFileSync } from 'node:fs';
import { createServer } from 'node:http';
import { resolve } from 'node:path';
import { text } from 'node:stream/consumers';
import { finished } from 'node:stream/promises';
import { parseArgs } from 'node:util';

try {
  const { values, positionals } = parseArgs({ options: { out: { type: 'string' } }, allowPositionals: true });
  if (positionals.length !== 1) throw new Error('Usage: node review.mjs plan.packed.html [--out plan.response.md]');
  const input = resolve(positionals[0]);
  const output = resolve(values.out ?? input.replace(/(?:\.packed)?\.html?$/i, '') + '.response.md');
  if (input === output) throw new Error('The response output must differ from the plan input.');
  const html = readFileSync(input, 'utf8');
  if (!/<html\b[^>]*\bdata-htmlplan-packed\b/i.test(html)) throw new Error('Expected a packed HTML plan. Run pack.mjs first.');

  const pagePath = `/${randomBytes(16).toString('hex')}/`;
  const responsePath = `${pagePath}response`;
  const meta = `<meta name="htmlplan-response" content="${responsePath}">`;
  const head = /<head\b[^>]*>/i.test(html) ? /<head\b[^>]*>/i : /<html\b[^>]*>/i;
  const page = html.replace(head, match => `${match}\n${meta}`);
  let origin, claimed = false;

  const stop = () => {
    server.close();
    server.closeAllConnections();
  };
  const fail = error => {
    console.error(error.message);
    process.exitCode = 1;
    stop();
  };

  const server = createServer(async (request, response) => {
    response.setHeader('Cache-Control', 'no-store');
    if (request.method === 'GET' && request.url === pagePath) {
      response.writeHead(200, { 'Content-Type': 'text/html;charset=UTF-8' });
      response.end(page);
      return;
    }
    if (request.url !== responsePath) {
      response.writeHead(404).end('Not found.');
      return;
    }
    if (request.method !== 'POST') {
      response.writeHead(405, { Allow: 'POST' }).end('Use POST.');
      return;
    }
    if (request.headers.origin !== origin) {
      response.writeHead(403).end('The response must come from this review page.');
      return;
    }

    let accepted = false;
    try {
      const markdown = await text(request);
      if (!markdown.trim()) {
        response.writeHead(400).end('The response must not be empty.');
        return;
      }
      if (claimed) {
        response.writeHead(409).end('This review already received a response.');
        return;
      }
      claimed = accepted = true;
      const outputIdentity = statSync(output, { throwIfNoEntry: false });
      if (outputIdentity) {
        const inputIdentity = statSync(input);
        if (outputIdentity.dev === inputIdentity.dev && outputIdentity.ino === inputIdentity.ino) {
          throw new Error('The response output must differ from the plan input.');
        }
      }
      writeFileSync(output, markdown, 'utf8');
      response.writeHead(200, { 'Content-Type': 'application/json', Connection: 'close' });
      const acknowledged = finished(response);
      // End unfinished requests only after the ACK connection closes normally.
      request.socket.once('close', () => server.closeAllConnections());
      response.end('{"received":true}');
      await acknowledged;
      process.stdout.write(markdown);
      // Preserve the ACK connection while HTTP completes its normal close.
      server.close();
    } catch (error) {
      if (request.aborted && !accepted) return;
      if (!response.headersSent) {
        response.writeHead(500, { 'Content-Type': 'text/plain', Connection: 'close' });
        response.end('Could not save the response.', () => fail(error));
      } else {
        fail(error);
      }
    }
  });

  server.on('error', fail);
  process.once('SIGINT', () => { process.exitCode = 130; stop(); });
  process.once('SIGTERM', () => { process.exitCode = 143; stop(); });
  server.listen(0, '127.0.0.1', () => {
    origin = `http://127.0.0.1:${server.address().port}`;
    console.error(`${origin}${pagePath}`);
  });
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
