import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { once } from 'node:events';
import { link, mkdtemp, readFile, rm, symlink, writeFile } from 'node:fs/promises';
import { createServer, request } from 'node:http';
import { createRequire } from 'node:module';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { test } from 'node:test';
import { fileURLToPath } from 'node:url';

const runtime = createRequire(import.meta.url)('../skills/html-plan/runtime/htmlplan.js');

async function startReview(t, extraArgs = []) {
  const directory = await mkdtemp(join(tmpdir(), 'html-plan-review-'));
  const input = join(directory, 'plan.packed.html');
  const original = '<!doctype html><html data-htmlplan-packed><head><title>Plan</title></head><body>Review</body></html>';
  await writeFile(input, original);
  const command = new URL('../skills/html-plan/runtime/review.mjs', import.meta.url);
  const child = spawn(process.execPath, [fileURLToPath(command), input, ...extraArgs], { stdio: ['ignore', 'pipe', 'pipe'] });
  let stdout = '', stderr = '';
  child.stdout.setEncoding('utf8').on('data', data => { stdout += data; });
  child.stderr.setEncoding('utf8').on('data', data => { stderr += data; });
  const exited = once(child, 'close');
  t.after(async () => {
    if (child.exitCode === null && child.signalCode === null) child.kill('SIGTERM');
    await exited;
    await rm(directory, { recursive: true });
  });
  const url = await new Promise((resolve, reject) => {
    child.stderr.on('data', () => {
      const address = stderr.match(/http:\/\/127\.0\.0\.1:\d+\/[^\s]+/);
      if (address) resolve(address[0]);
    });
    child.once('exit', () => reject(new Error(stderr || 'Review exited before it was ready.')));
    child.once('error', reject);
  });
  const page = await (await fetch(url)).text();
  const response = new URL(page.match(/<meta name="htmlplan-response" content="([^"]+)">/)[1], url);
  return { child, exited, input, original, directory, url, response, stdout: () => stdout, stderr: () => stderr };
}

function post(review, body, headers = {}) {
  return fetch(review.response, {
    method: 'POST',
    headers: { Origin: new URL(review.url).origin, 'Content-Type': 'text/plain;charset=UTF-8', ...headers },
    body,
  });
}

test('review waits for a response, saves exact Markdown, acknowledges, then exits', { timeout: 10000 }, async t => {
  const review = await startReview(t);
  assert.equal(review.child.exitCode, null);
  assert.equal(review.stdout(), '');
  const markdown = '# Re: Plan\n\n## Comments\n- 保留字段顺序。\n';
  const response = await post(review, markdown);
  assert.equal(response.status, 200);
  assert.deepEqual(await review.exited, [0, null]);
  // A reader that consumes the ACK after process exit must still get its full body.
  assert.deepEqual(await response.json(), { received: true });
  assert.equal(review.stdout(), markdown);
  assert.equal(await readFile(join(review.directory, 'plan.response.md'), 'utf8'), markdown);
  assert.equal(await readFile(review.input, 'utf8'), review.original);
});

test('unrelated, cross-origin, and empty requests cannot complete the review', { timeout: 10000 }, async t => {
  const review = await startReview(t);
  assert.equal((await fetch(new URL('/unrelated', review.url))).status, 404);
  assert.equal((await fetch(review.response)).status, 405);
  assert.equal((await post(review, 'wrong origin', { Origin: 'https://example.com' })).status, 403);
  assert.equal((await post(review, ' \n ')).status, 400);
  assert.equal(review.child.exitCode, null);
  assert.equal(review.stdout(), '');
  const response = await post(review, 'Accepted response\n');
  assert.deepEqual(await response.json(), { received: true });
  assert.deepEqual(await review.exited, [0, null]);
  assert.equal(review.stdout(), 'Accepted response\n');
});

test('save failure does not acknowledge or output a successful response', { timeout: 10000 }, async t => {
  const directory = await mkdtemp(join(tmpdir(), 'html-plan-output-'));
  t.after(() => rm(directory, { recursive: true }));
  const review = await startReview(t, ['--out', join(directory, 'missing', 'response.md')]);
  const response = await post(review, 'Feedback that must not be acknowledged\n');
  assert.equal(response.status, 500);
  assert.doesNotMatch(await response.text(), /"received":true/);
  assert.deepEqual(await review.exited, [1, null]);
  assert.equal(review.stdout(), '');
  assert.match(review.stderr(), /ENOENT/);
});

for (const [kind, createLink] of [['symlink', symlink], ['hard link', link]]) {
  test(`an output ${kind} cannot replace the packed input`, { timeout: 10000 }, async t => {
    const review = await startReview(t);
    await createLink(review.input, join(review.directory, 'plan.response.md'));
    const response = await post(review, 'Feedback must not replace the plan\n');
    assert.equal(response.status, 500);
    await response.text();
    assert.deepEqual(await review.exited, [1, null]);
    assert.equal(review.stdout(), '');
    assert.equal(await readFile(review.input, 'utf8'), review.original);
  });
}

test('an incomplete request cannot keep a completed review alive', { timeout: 10000 }, async t => {
  const review = await startReview(t);
  const pending = request(review.response, {
    method: 'POST',
    headers: { Origin: new URL(review.url).origin, 'Content-Length': '100', Expect: '100-continue' },
  });
  pending.on('error', error => { assert.equal(error.code, 'ECONNRESET'); });
  t.after(() => pending.destroy());
  const closed = new Promise(resolve => pending.once('close', resolve));
  const continued = once(pending, 'continue');
  pending.flushHeaders();
  await continued;
  pending.write('unfinished');
  const response = await post(review, 'The one accepted response\n');
  assert.deepEqual(await response.json(), { received: true });
  assert.deepEqual(await review.exited, [0, null]);
  await closed;
  assert.equal(review.stdout(), 'The one accepted response\n');
});

test('cancellation ends the wait without fabricating feedback', { timeout: 10000 }, async t => {
  const review = await startReview(t);
  review.child.kill('SIGTERM');
  const [code, signal] = await review.exited;
  assert.ok(code !== 0 || signal !== null);
  assert.equal(review.stdout(), '');
  await assert.rejects(readFile(join(review.directory, 'plan.response.md')), { code: 'ENOENT' });
});

test('the response workflow waits for an explicit ACK before its close callback', { timeout: 10000 }, async t => {
  let release;
  const requested = new Promise(resolve => { release = resolve; });
  const server = createServer((request, response) => {
    request.resume();
    release(response);
  }).listen(0, '127.0.0.1');
  await once(server, 'listening');
  t.after(() => { server.close(); server.closeAllConnections(); });
  let closed = false;
  const sending = runtime.sendResponse(`http://127.0.0.1:${server.address().port}/`, 'Feedback\n', fetch, () => { closed = true; });
  const response = await requested;
  assert.equal(closed, false);
  response.setHeader('Content-Type', 'application/json');
  response.end('{"received":true}');
  await sending;
  assert.equal(closed, true);
});

test('HTTP rejection and a missing ACK never close the page', { timeout: 10000 }, async t => {
  const server = createServer((request, response) => {
    request.resume();
    response.writeHead(request.url === '/failure' ? 500 : 200, { 'Content-Type': 'application/json' });
    response.end(request.url === '/failure' ? '{"error":"save failed"}' : '{"received":false}');
  }).listen(0, '127.0.0.1');
  await once(server, 'listening');
  t.after(() => { server.close(); server.closeAllConnections(); });
  let closed = false;
  for (const path of ['/failure', '/missing-ack']) {
    await assert.rejects(runtime.sendResponse(`http://127.0.0.1:${server.address().port}${path}`, 'Feedback\n', fetch, () => { closed = true; }));
    assert.equal(closed, false);
  }
});
