import { describe, expect, test } from 'bun:test';
import {
	loadHomepageStoreMetadata,
	type HomepageStoreFetch,
	type PlayStoreListing
} from '../src/lib/server/homepage_store_metadata';

const APPLE_LOOKUP_PATH = '/lookup?id=6754315964';

function serveAppleLookup(response: () => Response) {
	const requestedPaths: string[] = [];
	const server = Bun.serve({
		hostname: '127.0.0.1',
		port: 0,
		fetch(request) {
			const url = new URL(request.url);
			requestedPaths.push(`${url.pathname}${url.search}`);
			return response();
		}
	});

	const fetch: HomepageStoreFetch = (url) => {
		const upstream = new URL(url);
		if (upstream.origin !== 'https://itunes.apple.com') {
			throw new Error(`Unexpected App Store URL: ${url}`);
		}
		return globalThis.fetch(new URL(`${upstream.pathname}${upstream.search}`, server.url));
	};

	return { server, fetch, requestedPaths };
}

describe('loadHomepageStoreMetadata', () => {
	test('preserves Google Play metadata across Apple HTTP and JSON errors', async () => {
		let response = () => new Response(null, { status: 503 });
		const apple = serveAppleLookup(() => response());

		try {
			for (const failedResponse of [
				() => new Response(null, { status: 503 }),
				() => new Response('{', { headers: { 'content-type': 'application/json' } })
			]) {
				response = failedResponse;
				const metadata = await loadHomepageStoreMetadata({
					fetch: apple.fetch,
					loadPlayStoreListing: async () => ({
						available: true,
						score: 4.5,
						ratings: 20,
						price: 3.99,
						currency: 'USD'
					})
				});

				expect(metadata).toEqual({
					aggregateRating: { ratingValue: '4.5', ratingCount: 20 },
					appStorePrice: null,
					playStorePrice: '3.99'
				});
			}

			expect(apple.requestedPaths).toEqual([APPLE_LOOKUP_PATH, APPLE_LOOKUP_PATH]);
		} finally {
			await apple.server.stop(true);
		}
	});

	test('preserves Google Play metadata when the Apple transport rejects', async () => {
		const metadata = await loadHomepageStoreMetadata({
			fetch: async () => {
				throw new Error('connection refused');
			},
			loadPlayStoreListing: async () => ({
				available: true,
				score: 4.5,
				ratings: 20,
				price: 3.99,
				currency: 'USD'
			})
		});

		expect(metadata).toEqual({
			aggregateRating: { ratingValue: '4.5', ratingCount: 20 },
			appStorePrice: null,
			playStorePrice: '3.99'
		});
	});

	test('preserves Apple metadata when Google Play fails or is unavailable', async () => {
		const apple = serveAppleLookup(() =>
			Response.json({
				results: [
					{
						averageUserRating: 4,
						userRatingCount: 10,
						price: 4.99,
						currency: 'USD'
					}
				]
			})
		);
		const failedListings: Array<() => Promise<PlayStoreListing>> = [
			async () => {
				throw new Error('offline');
			},
			async () => ({ available: false, score: 5, ratings: 99, price: 3.99, currency: 'USD' })
		];

		try {
			for (const loadPlayStoreListing of failedListings) {
				const metadata = await loadHomepageStoreMetadata({ fetch: apple.fetch, loadPlayStoreListing });
				expect(metadata).toEqual({
					aggregateRating: { ratingValue: '4.0', ratingCount: 10 },
					appStorePrice: '4.99',
					playStorePrice: null
				});
			}

			expect(apple.requestedPaths).toEqual([APPLE_LOOKUP_PATH, APPLE_LOOKUP_PATH]);
		} finally {
			await apple.server.stop(true);
		}
	});

	test('normalizes malformed store prices independently', async () => {
		let appStoreResult: { price: unknown; currency: unknown } = { price: '4.99', currency: 'USD' };
		const apple = serveAppleLookup(() => Response.json({ results: [appStoreResult] }));
		const cases = [
			{
				appStore: { price: '4.99', currency: 'USD' },
				playStore: { available: true, price: 3.99, currency: 'USD' },
				expected: { appStorePrice: null, playStorePrice: '3.99' }
			},
			{
				appStore: { price: 4.99, currency: 'USD' },
				playStore: { available: true, price: 3.99, currency: 'EUR' },
				expected: { appStorePrice: '4.99', playStorePrice: null }
			}
		] as const;

		try {
			for (const { appStore, playStore, expected } of cases) {
				appStoreResult = appStore;
				const metadata = await loadHomepageStoreMetadata({
					fetch: apple.fetch,
					loadPlayStoreListing: async () => playStore
				});
				expect(metadata).toEqual({ aggregateRating: null, ...expected });
			}
		} finally {
			await apple.server.stop(true);
		}
	});

	test('weights store ratings by rating count and rounds to one decimal place', async () => {
		const apple = serveAppleLookup(() =>
			Response.json({
				results: [
					{
						averageUserRating: 4,
						userRatingCount: 10,
						price: 4.99,
						currency: 'USD'
					}
				]
			})
		);

		try {
			const metadata = await loadHomepageStoreMetadata({
				fetch: apple.fetch,
				loadPlayStoreListing: async () => ({
					available: true,
					score: 5,
					ratings: 30,
					price: 3.99,
					currency: 'USD'
				})
			});

			expect(metadata).toEqual({
				aggregateRating: { ratingValue: '4.8', ratingCount: 40 },
				appStorePrice: '4.99',
				playStorePrice: '3.99'
			});
			expect(apple.requestedPaths).toEqual([APPLE_LOOKUP_PATH]);
		} finally {
			await apple.server.stop(true);
		}
	});
});
