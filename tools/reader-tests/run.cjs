// Resolve the pinned browser tooling here; Flutter owns the loopback fixtures.
const {existsSync} = require('node:fs');
const {resolve} = require('node:path');
const {spawnSync} = require('node:child_process');
const playwrightPath = process.env.PLEZY_PLAYWRIGHT_PATH || require.resolve('playwright');
const {chromium} = require(playwrightPath);
const chrome = process.env.PLEZY_CHROME_PATH || chromium.executablePath();
if (!existsSync(chrome)) {
  console.error('Install the pinned browser with: npm exec -- playwright install chromium');
  process.exit(1);
}
const root = resolve(__dirname, '../..');
const env = {...process.env, PLEZY_PLAYWRIGHT_PATH: playwrightPath, PLEZY_CHROME_PATH: chrome};
for (const [command, args] of [
  [process.execPath, ['--test', 'test/sources/fixtures/comic_layout.test.mjs']],
  [process.platform === 'win32' ? 'flutter.bat' : 'flutter', ['test', '--no-pub', 'test/sources/publication_browser_test.dart']],
]) {
  const result = spawnSync(command, args, {cwd: root, env, stdio: 'inherit', timeout: 240000});
  if (result.error) console.error(result.error.message);
  if (result.status !== 0) process.exit(result.status || 1);
}
