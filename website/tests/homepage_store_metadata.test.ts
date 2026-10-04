import { describe, expect, test } from 'bun:test';
import {
	loadHomepageStoreMetadata,
	type HomepageStoreFetch,
	type PlayStoreListing
} from '../src/lib/server/homepage_store_metadata';

const APP_STORE_LOOKUP_URL = 'https://itunes.apple.com/lookup?id=6754315964';

function appStoreResult(overrides: Record<string, unknown> = {}): Response {
	return Response.json({
		results: [{ averageUserRating: 4, userRatingCount: 10, price: 4.99, currency: 'USD', ...overrides }]
	});
}

function playStoreListing(overrides: Partial<PlayStoreListing> = {}): PlayStoreListing {
	return { available: true, score: 4.5, ratings: 20, price: 3.99, currency: 'USD', ...overrides };
}

describe('loadHomepageStoreMetadata', () => {
	test('preserves Google Play metadata across Apple transport, HTTP, and JSON errors', async () => {
		const failedFetches: HomepageStoreFetch[] = [
			async () => {
				throw new Error('connection refused');
			},
			async () => new Response(null, { status: 503 }),
			async () => new Response('{', { headers: { 'content-type': 'application/json' } })
		];

		for (const fetch of failedFetches) {
			const metadata = await loadHomepageStoreMetadata({
				fetch,
				loadPlayStoreListing: async () => playStoreListing()
			});
			expect(metadata).toEqual({
				aggregateRating: { ratingValue: '4.5', ratingCount: 20 },
				appStorePrice: null,
				playStorePrice: '3.99'
			});
		}
	});

	test('preserves Apple metadata when Google Play fails or is unavailable', async () => {
		const failedListings: Array<() => Promise<PlayStoreListing>> = [
			async () => {
				throw new Error('offline');
			},
			async () => playStoreListing({ available: false, score: 5, ratings: 99 })
		];

		for (const loadPlayStoreListing of failedListings) {
			const metadata = await loadHomepageStoreMetadata({
				fetch: async () => appStoreResult(),
				loadPlayStoreListing
			});
			expect(metadata).toEqual({
				aggregateRating: { ratingValue: '4.0', ratingCount: 10 },
				appStorePrice: '4.99',
				playStorePrice: null
			});
		}
	});

	test('normalizes malformed store prices independently', async () => {
		const cases = [
			{
				appStore: { price: '4.99' },
				playStore: {},
				expected: { appStorePrice: null, playStorePrice: '3.99' }
			},
			{
				appStore: {},
				playStore: { currency: 'EUR' },
				expected: { appStorePrice: '4.99', playStorePrice: null }
			}
		] as const;

		for (const { appStore, playStore, expected } of cases) {
			const metadata = await loadHomepageStoreMetadata({
				fetch: async () => appStoreResult(appStore),
				loadPlayStoreListing: async () => playStoreListing(playStore)
			});
			expect(metadata).toMatchObject(expected);
		}
	});

	test('weights store ratings by rating count and rounds to one decimal place', async () => {
		const requestedUrls: string[] = [];
		const metadata = await loadHomepageStoreMetadata({
			fetch: async (url) => {
				requestedUrls.push(url);
				return appStoreResult();
			},
			loadPlayStoreListing: async () => playStoreListing({ score: 5, ratings: 30 })
		});

		expect(requestedUrls).toEqual([APP_STORE_LOOKUP_URL]);
		expect(metadata).toEqual({
			aggregateRating: { ratingValue: '4.8', ratingCount: 40 },
			appStorePrice: '4.99',
			playStorePrice: '3.99'
		});
	});
});
