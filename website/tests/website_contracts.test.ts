import { afterEach, beforeEach, describe, expect, mock, test } from 'bun:test';

import {
  detectMobileStorePlatform,
  linuxArchitectures,
  storeOptionsForPlatform,
} from '../src/lib/content/downloads';
import {
  buildSoftwareApplicationOffers,
  normalizeUsdStorePrice,
} from '../src/lib/content/software_app_offers';

type PlayStoreFixture = {
  available?: boolean;
  price?: unknown;
  currency?: unknown;
  score?: number;
  ratings?: number;
};

let playStoreFixture: PlayStoreFixture | Error;

mock.module('google-play-scraper', () => ({
  default: {
    app: async () => {
      if (playStoreFixture instanceof Error) throw playStoreFixture;
      return playStoreFixture;
    },
  },
}));

// Dynamic loading is intentional here: Bun must install the scraper mock before
// the route first loads its optional external dependency.
const { load } = await import('../src/routes/+page.server');

function appleFetch(body: unknown, status = 200): typeof fetch {
  return (async () => new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json' },
  })) as typeof fetch;
}

async function loadHomepage(fetcher: typeof fetch) {
  return await (load as (event: { fetch: typeof fetch }) => Promise<{
    appStorePrice: string | null;
    playStorePrice: string | null;
    aggregateRating: { ratingValue: string; ratingCount: number } | null;
  }>)({ fetch: fetcher });
}

beforeEach(() => {
  playStoreFixture = {
    available: true,
    price: 4.99,
    currency: 'USD',
    score: 4.5,
    ratings: 10,
  };
});

afterEach(() => {
  mock.restore();
});

describe('download component contracts', () => {
  test('detects mobile stores without browser globals', () => {
    expect(detectMobileStorePlatform()).toBe('unknown');
    expect(detectMobileStorePlatform({ userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0)' })).toBe('ios');
    expect(detectMobileStorePlatform({ userAgent: 'Mozilla/5.0 (Linux; Android 15)' })).toBe('android');
    expect(detectMobileStorePlatform({
      userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15)',
      platform: 'MacIntel',
      maxTouchPoints: 5,
    })).toBe('ios');
    expect(detectMobileStorePlatform({
      userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15)',
      platform: 'MacIntel',
      maxTouchPoints: 0,
    })).toBe('unknown');
  });

  test('unknown platforms retain both truthful store choices', () => {
    expect(storeOptionsForPlatform('unknown').map((option) => option.label)).toEqual(['App Store', 'Google Play']);
    expect(storeOptionsForPlatform('ios').map((option) => option.label)).toEqual(['App Store']);
    expect(storeOptionsForPlatform('android').map((option) => option.label)).toEqual(['Google Play']);
  });

  test('Linux disclosure data contains both architectures and eight unique native links', () => {
    expect(linuxArchitectures.map((architecture) => architecture.label)).toEqual(['x64 (Intel/AMD)', 'ARM64']);
    const links = linuxArchitectures.flatMap((architecture) => architecture.formats.map((format) => format.url));
    expect(links).toHaveLength(8);
    expect(new Set(links).size).toBe(8);
    expect(links.every((url) => url.startsWith('https://github.com/edde746/plezy/releases/latest/download/'))).toBe(true);
  });
});

describe('homepage store metadata', () => {
  test('normalizes only finite nonnegative numeric USD prices', () => {
    expect(normalizeUsdStorePrice(4.99, 'USD')).toBe('4.99');
    expect(normalizeUsdStorePrice(0, 'USD')).toBe('0');
    for (const value of [null, undefined, '4.99', Number.NaN, Number.POSITIVE_INFINITY, -1]) {
      expect(normalizeUsdStorePrice(value, 'USD')).toBeNull();
    }
    expect(normalizeUsdStorePrice(4.99, undefined)).toBeNull();
    expect(normalizeUsdStorePrice(4.99, 'EUR')).toBeNull();
  });

  test('keeps Google Play metadata when the App Store request fails', async () => {
    const data = await loadHomepage((async () => {
      throw new Error('offline');
    }) as typeof fetch);
    expect(data.appStorePrice).toBeNull();
    expect(data.playStorePrice).toBe('4.99');
    expect(data.aggregateRating).toEqual({ ratingValue: '4.5', ratingCount: 10 });
  });

  test('keeps App Store metadata when Google Play is unavailable', async () => {
    playStoreFixture = { available: false, price: 0, currency: 'USD' };
    const data = await loadHomepage(appleFetch({
      results: [{ price: 5.99, currency: 'USD', averageUserRating: 4, userRatingCount: 20 }],
    }));
    expect(data.appStorePrice).toBe('5.99');
    expect(data.playStorePrice).toBeNull();
    expect(data.aggregateRating).toEqual({ ratingValue: '4.0', ratingCount: 20 });
  });

  test('keeps App Store metadata when Google Play throws', async () => {
    playStoreFixture = new Error('scraper failed');
    const data = await loadHomepage(appleFetch({
      results: [{ price: 5.99, currency: 'USD' }],
    }));
    expect(data.appStorePrice).toBe('5.99');
    expect(data.playStorePrice).toBeNull();
  });

  test('rejects non-OK and malformed store responses independently', async () => {
    playStoreFixture = { price: 'free', currency: 'USD' };
    const data = await loadHomepage(appleFetch({ results: [{ price: 4.99, currency: 'USD' }] }, 503));
    expect(data.appStorePrice).toBeNull();
    expect(data.playStorePrice).toBeNull();
  });

  test('retains paid store URLs when live prices are unavailable', () => {
    const unavailable = buildSoftwareApplicationOffers({ appStorePrice: null, playStorePrice: null });
    expect(unavailable.map((offer) => offer.category)).toEqual([
      'App Store',
      'Google Play',
      'Amazon Appstore',
      'GitHub',
    ]);
    expect(unavailable.find((offer) => offer.category === 'App Store')).toMatchObject({
      url: 'https://apps.apple.com/us/app/id6754315964',
    });
    expect(unavailable.find((offer) => offer.category === 'Google Play')).toMatchObject({
      url: 'https://play.google.com/store/apps/details?id=com.edde746.plezy',
    });
    expect(unavailable.filter((offer) => offer.price === '0').map((offer) => offer.category)).toEqual(['GitHub']);
    expect(
      unavailable
        .filter((offer) => ['App Store', 'Google Play'].includes(offer.category))
        .every((offer) => !('price' in offer)),
    ).toBe(true);

    const available = buildSoftwareApplicationOffers({ appStorePrice: '5.99', playStorePrice: '4.99' });
    expect(available.find((offer) => offer.category === 'App Store')).toMatchObject({ price: '5.99', priceCurrency: 'USD' });
    expect(available.find((offer) => offer.category === 'Google Play')).toMatchObject({ price: '4.99', priceCurrency: 'USD' });
  });
});
