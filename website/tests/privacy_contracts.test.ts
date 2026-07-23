import { afterAll, beforeAll, describe, expect, test } from 'bun:test';
import { createServer, type ViteDevServer } from 'vite';

import { faqs, faqSchemaMainEntity, watchTogetherFaqAnswer } from '../src/lib/content/faqs';
import { csr, prerender } from '../src/routes/privacy/+page';

let vite: ViteDevServer;
let renderedPrivacyHead: string;
let renderedPrivacyHtml: string;
let privacySource: string;

beforeAll(async () => {
  vite = await createServer({
    root: process.cwd(),
    appType: 'custom',
    server: { middlewareMode: true },
  });
  const [{ default: privacyPage }, { render }] = await Promise.all([
    vite.ssrLoadModule('/src/routes/privacy/+page.svelte'),
    vite.ssrLoadModule('svelte/server'),
  ]);
  const rendered = render(privacyPage);
  renderedPrivacyHead = rendered.head;
  renderedPrivacyHtml = rendered.body;
  privacySource = await Bun.file('src/routes/privacy/+page.svelte').text();
}, 90_000);

afterAll(async () => {
  await vite?.close();
}, 30_000);

function visibleText(html: string): string {
  return html
    .replace(/<[^>]+>/g, ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&#39;', "'")
    .replace(/\s+/g, ' ')
    .trim();
}

describe('privacy page', () => {
  test('remains a prerendered, server-rendered route', () => {
    expect(prerender).toBe(true);
    expect(csr).toBe(false);
    expect(renderedPrivacyHead).toContain('<title>Privacy Policy - Plezy</title>');
    expect(renderedPrivacyHead).toContain('<link rel="canonical" href="https://plezy.app/privacy"');
  });

  test('renders a concise semantic policy without inventory cards or grids', () => {
    for (const heading of [
      'Overview',
      'Data on your device',
      'Connections and third parties',
      'Optional Plezy services',
      'Your choices',
      'Retention and security',
      'Contact and changes',
    ]) {
      expect(renderedPrivacyHtml).toContain(`>${heading}</h2>`);
    }

    expect(renderedPrivacyHtml.match(/<section/g)).toHaveLength(7);
    expect(renderedPrivacyHtml).not.toContain('flow-card');
    expect(renderedPrivacyHtml).not.toContain('<dl');
    expect(renderedPrivacyHtml).not.toContain('<ul');
    expect(privacySource).not.toContain('display: grid');
    expect(visibleText(renderedPrivacyHtml).split(' ').length).toBeLessThan(900);
  });

  test('uses first-party language and preserves the material privacy boundaries', () => {
    const text = visibleText(renderedPrivacyHtml);

    expect(text).not.toMatch(/\brepositor(?:y|ies)\b/i);
    expect(text).not.toMatch(/repository-verified/i);
    expect(text).toContain('We do not sell personal data or use it for advertising');
    expect(text).toContain('access tokens and other sign-in data');
    expect(text).toContain('may contain a server access credential');
    expect(text).toContain('does not carry the media stream or your media-server credentials');
    expect(text).toContain('Support-log uploads are always explicit');
    expect(text).toContain('up to 90 days');
    expect(text).toContain('retrieved for three days');
    expect(text).toContain('no more than three hours');
    expect(renderedPrivacyHtml).toContain('rel="noopener noreferrer"');
  });

  test('keeps the Watch Together disclosure aligned with visible FAQ content', () => {
    const faqIndex = faqs.findIndex((faq) => faq.id === 'watch-together');
    expect(faqIndex).toBeGreaterThanOrEqual(0);
    expect(faqs[faqIndex]!.answer).toBe(watchTogetherFaqAnswer);
    expect(faqSchemaMainEntity[faqIndex]!.acceptedAnswer.text).toBe(watchTogetherFaqAnswer);
    expect(watchTogetherFaqAnswer).toContain('server and media identifiers');
    expect(watchTogetherFaqAnswer).toContain('does not relay the media stream');
    expect(watchTogetherFaqAnswer).toContain('custom relay');
  });
});
