import { describe, expect, test } from 'bun:test';
import {
	loadHomepageStoreMetadata,
	type HomepageStoreFetch,
	type PlayStoreListing
} from '../src/lib/server/homepage_store_metadata';

const APP_STORE_LOOKUP_URL = 'https://itunes.apple.com/lookup?id=6754315964';

function appStoreResponse(overrides: Record<string, unknown> = {}): Response {
	return Response.json({
		resultCount: 1,
		results: [
			{
				averageUserRating: 4,
				userRatingCount: 10,
				price: 4.99,
				currency: 'USD',
				...overrides
			}
		]
	});
}

function playStoreListing(overrides: Partial<PlayStoreListing> = {}): PlayStoreListing {
	return {
		available: true,
		score: 4.5,
		ratings: 20,
		price: 3.99,
		currency: 'USD',
		...overrides
	};
}

async function expectAppleFailureKeepsGoogleMetadata(fetch: HomepageStoreFetch): Promise<void> {
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

async function expectGoogleFailureKeepsAppleMetadata(
	loadPlayStoreListing: () => Promise<PlayStoreListing>
): Promise<void> {
	const metadata = await loadHomepageStoreMetadata({
		fetch: async () => appStoreResponse(),
		loadPlayStoreListing
	});

	expect(metadata).toEqual({
		aggregateRating: { ratingValue: '4.0', ratingCount: 10 },
		appStorePrice: '4.99',
		playStorePrice: null
	});
}

describe('loadHomepageStoreMetadata failure isolation', () => {
	test('an App Store fetch exception does not discard Google Play metadata', async () => {
		await expectAppleFailureKeepsGoogleMetadata(async () => {
			throw new Error('offline');
		});
	});

	test('a non-OK App Store response does not discard Google Play metadata', async () => {
		await expectAppleFailureKeepsGoogleMetadata(
			async () => new Response(null, { status: 503 })
		);
	});

	test('malformed App Store JSON does not discard Google Play metadata', async () => {
		await expectAppleFailureKeepsGoogleMetadata(
			async () => new Response('{', { headers: { 'content-type': 'application/json' } })
		);
	});

	test('a Google Play exception does not discard App Store metadata', async () => {
		await expectGoogleFailureKeepsAppleMetadata(async () => {
			throw new Error('offline');
		});
	});

	test('an unavailable Google Play listing does not discard App Store metadata', async () => {
		await expectGoogleFailureKeepsAppleMetadata(async () =>
			playStoreListing({ available: false })
		);
	});
});

describe('loadHomepageStoreMetadata prices and ratings', () => {
	test('normalizes each store price independently', async () => {
		const malformedApplePrice = await loadHomepageStoreMetadata({
			fetch: async () => appStoreResponse({ price: '4.99' }),
			loadPlayStoreListing: async () => playStoreListing()
		});
		expect(malformedApplePrice.appStorePrice).toBeNull();
		expect(malformedApplePrice.playStorePrice).toBe('3.99');

		const malformedGooglePrice = await loadHomepageStoreMetadata({
			fetch: async () => appStoreResponse(),
			loadPlayStoreListing: async () => playStoreListing({ currency: 'EUR' })
		});
		expect(malformedGooglePrice.appStorePrice).toBe('4.99');
		expect(malformedGooglePrice.playStorePrice).toBeNull();
	});

	test('computes the count-weighted aggregate to one decimal place', async () => {
		const requestedUrls: string[] = [];
		const metadata = await loadHomepageStoreMetadata({
			fetch: async (url) => {
				requestedUrls.push(url);
				return appStoreResponse({ averageUserRating: 4, userRatingCount: 10 });
			},
			loadPlayStoreListing: async () =>
				playStoreListing({ score: 5, ratings: 30 })
		});

		expect(requestedUrls).toEqual([APP_STORE_LOOKUP_URL]);
		expect(metadata.aggregateRating).toEqual({
			ratingValue: '4.8',
			ratingCount: 40
		});
	});
});
