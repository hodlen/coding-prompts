// install.py promises a rerunnable install: a second run in the same shell,
// before PATH picks up uv's tool directory, still merges every setting, and
// leaves each file as the first run did. It also replaces gate hooks left by a
// moved checkout without touching the user's other hooks. Integration check:
// it installs the real tools, so it needs uv and network access.
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { homedir, tmpdir } from 'node:os';
import { join } from 'node:path';
import { test } from 'node:test';
import { fileURLToPath } from 'node:url';

const repo = fileURLToPath(new URL('..', import.meta.url));
const hasUv = spawnSync('uv', ['--version']).status === 0;
const gate = join(repo, 'hooks/cleanup-gate.sh');
const staleGate = '/moved/coding-prompts/hooks/cleanup-gate.sh';

// Keep network settings, but send every write the installer makes into `home`.
// PATH stays as is, so it lacks the tool directory the first run adds to shell files.
function isolated(home) {
  const env = { ...process.env, HOME: home, SHELL: '/bin/bash' };
  for (const name of ['XDG_CONFIG_HOME', 'XDG_DATA_HOME', 'XDG_STATE_HOME', 'UV_TOOL_DIR', 'UV_TOOL_BIN_DIR', 'GIT_CONFIG_GLOBAL']) {
    delete env[name];
  }
  // Shared caches only save downloads.
  env.UV_CACHE_DIR ??= join(homedir(), '.cache/uv');
  env.XDG_CACHE_HOME ??= join(homedir(), '.cache');
  return env;
}

test('a second install in an unrefreshed shell completes with the same files', { skip: !hasUv && 'uv is not installed', timeout: 600_000 }, async t => {
  const home = await mkdtemp(join(tmpdir(), 'agents-install-'));
  t.after(() => rm(home, { recursive: true, force: true }));
  await mkdir(join(home, '.claude'), { recursive: true });
  await writeFile(join(home, '.claude/settings.json'), JSON.stringify({
    hooks: {
      Stop: [
        { matcher: '', hooks: [{ type: 'command', command: staleGate }] },
        { matcher: '', hooks: [{ type: 'command', command: '/usr/bin/true' }] },
        { matcher: 'kept-empty', hooks: [] },
      ],
    },
  }));
  const install = () => spawnSync(join(repo, 'install.py'), {
    cwd: home,
    encoding: 'utf8',
    env: isolated(home),
  });
  const managed = ['.claude/settings.json', '.codex/hooks.json', '.codex/config.toml', '.config/git/ignore'];
  const snapshot = async () => Promise.all(managed.map(path => readFile(join(home, path), 'utf8')));

  const first = install();
  assert.equal(first.status, 0, first.stderr);
  const afterFirst = await snapshot();
  const second = install();
  assert.equal(second.status, 0, second.stderr);
  assert.deepEqual(await snapshot(), afterFirst);

  const settings = JSON.parse(afterFirst[0]);
  const stop = settings.hooks.Stop.flatMap(group => group.hooks.map(hook => hook.command));
  assert.deepEqual(stop.filter(command => command.endsWith('cleanup-gate.sh')), [gate]);
  assert.ok(stop.includes('/usr/bin/true'));
  assert.ok(settings.hooks.Stop.some(group => group.matcher === 'kept-empty'));
  const ignored = afterFirst[3].split('\n');
  for (const pattern of ['/.metrics/', '/.coverage', '/target/coverage/']) {
    assert.equal(ignored.filter(line => line === pattern).length, 1, pattern);
  }
  for (const tool of ['crapper', 'dryer', 'mutator']) {
    assert.ok(existsSync(join(home, '.local/bin', tool)), tool);
  }
});
