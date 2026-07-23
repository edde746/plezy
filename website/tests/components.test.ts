import { afterAll, beforeAll, describe, expect, test } from 'bun:test';
import { createServer, type ViteDevServer } from 'vite';

let vite: ViteDevServer;

beforeAll(async () => {
  vite = await createServer({
    root: process.cwd(),
    appType: 'custom',
    server: { middlewareMode: true },
  });
}, 30_000);

afterAll(async () => {
  await vite?.close();
}, 30_000);

async function renderComponent(path: string): Promise<string> {
  const [{ default: component }, { render: renderOnViteGraph }] = await Promise.all([
    vite.ssrLoadModule(path),
    vite.ssrLoadModule('svelte/server'),
  ]);
  return renderOnViteGraph(component).body;
}

describe('SSR component contracts', () => {
  test('Logo renders the one managed asset as a decorative non-draggable image', async () => {
    const html = await renderComponent('/src/lib/components/Logo.svelte');
    expect(html).toContain('<img');
    expect(html).toContain('alt=""');
    expect(html).toContain('aria-hidden="true"');
    expect(html).toContain('draggable="false"');
    expect(html).not.toContain('<path');
  }, 30_000);

  test('Linux downloads prerender as an ordinary inert disclosure', async () => {
    const html = await renderComponent('/src/lib/components/DownloadButtons.svelte');
    expect(html).toContain('aria-expanded="false"');
    expect(html).toContain('aria-controls="');
    expect(html).toContain('aria-hidden="true"');
    expect(html).toContain('inert');
    expect(html).not.toContain('aria-haspopup');
    expect(html).not.toContain('role="menu"');
    expect(html).not.toContain('role="menuitem"');
    expect(html.match(/plezy-linux-(?:x64|arm64)\.(?:deb|rpm|pkg\.tar\.zst|tar\.gz)/g)).toHaveLength(8);
  }, 30_000);
  test('Screenshots prerender stable regions but only the initial lazy phone images', async () => {
    const html = await renderComponent('/src/lib/components/Screenshots.svelte');
    for (const device of ['phone', 'tablet', 'desktop', 'tv']) {
      expect(html).toContain(`id="screenshots-${device}-panel"`);
    }
    expect(html.match(/<picture\b/g)).toHaveLength(4);
    expect(html.match(/loading="lazy"/g)).toHaveLength(4);
    expect(html.match(/width="\d+" height="\d+"/g)).toHaveLength(4);
    expect(html).toContain('alt="Plezy home screen"');
    expect(html).toContain('style="opacity: 1; transform: translateY(0px);');
    expect(html).not.toContain('alt="Plezy on tablet - home"');
    expect(html).not.toContain('alt="Plezy on desktop - home"');
    expect(html).not.toContain('alt="Plezy on TV - home"');
  }, 30_000);
});
