import { describe, expect, test } from 'bun:test';
import {
	detectMobileStorePlatform,
	linuxArchitectures,
	storeOptionsForPlatform
} from '../src/lib/content/downloads';
import {
	faqSchemaMainEntity,
	faqs,
	watchTogetherFaqAnswer
} from '../src/lib/content/faqs';
import {
	buildSoftwareApplicationOffers,
	normalizeUsdStorePrice
} from '../src/lib/content/software_app_offers';
import { csr as privacyCsr } from '../src/routes/privacy/+page';

describe('mobile store selection', () => {
	test('treats missing and unrecognized client evidence as unknown', () => {
		expect(detectMobileStorePlatform()).toBe('unknown');
		expect(
			detectMobileStorePlatform({
				userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
				platform: 'Win32',
				maxTouchPoints: 0
			})
		).toBe('unknown');
	});

	test('detects iOS and Android user agents', () => {
		expect(
			detectMobileStorePlatform({
				userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X)'
			})
		).toBe('ios');
		expect(
			detectMobileStorePlatform({
				userAgent: 'Mozilla/5.0 (Linux; Android 15; Pixel 9)'
			})
		).toBe('android');
	});

	test('distinguishes desktop-mode iPadOS from a non-touch Mac', () => {
		const desktopSafari = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)';
		expect(
			detectMobileStorePlatform({
				userAgent: desktopSafari,
				platform: 'MacIntel',
				maxTouchPoints: 5
			})
		).toBe('ios');
		expect(
			detectMobileStorePlatform({
				userAgent: desktopSafari,
				platform: 'MacIntel',
				maxTouchPoints: 0
			})
		).toBe('unknown');
	});

	test('shows only the matching store when known and both stores when unknown', () => {
		expect(storeOptionsForPlatform('ios').map((option) => option.id)).toEqual(['app-store']);
		expect(storeOptionsForPlatform('android').map((option) => option.id)).toEqual([
			'play-store'
		]);
		expect(storeOptionsForPlatform('unknown').map((option) => option.id)).toEqual([
			'app-store',
			'play-store'
		]);
	});
});

describe('Linux download inventory', () => {
	test('keeps a unique four-format artifact matrix for x64 and ARM64', () => {
		const artifactNames = linuxArchitectures.map((architecture) =>
			architecture.formats.map(({ url }) => url.slice(url.lastIndexOf('/') + 1))
		);

		expect(linuxArchitectures.map(({ label }) => label)).toEqual(['x64 (Intel/AMD)', 'ARM64']);
		expect(artifactNames).toEqual([
			[
				'plezy-linux-x64.deb',
				'plezy-linux-x64.rpm',
				'plezy-linux-x64.pkg.tar.zst',
				'plezy-linux-x64.tar.gz'
			],
			[
				'plezy-linux-arm64.deb',
				'plezy-linux-arm64.rpm',
				'plezy-linux-arm64.pkg.tar.zst',
				'plezy-linux-arm64.tar.gz'
			]
		]);

		const urls = linuxArchitectures.flatMap((architecture) =>
			architecture.formats.map(({ url }) => url)
		);
		expect(new Set(urls).size).toBe(8);
		expect(
			urls.every((url) =>
				url.startsWith('https://github.com/edde746/plezy/releases/latest/download/')
			)
		).toBe(true);
	});
});

describe('software application offers', () => {
	test('accepts only finite nonnegative numeric USD prices', () => {
		expect(normalizeUsdStorePrice(0, 'USD')).toBe('0');
		expect(normalizeUsdStorePrice(4.99, 'USD')).toBe('4.99');

		for (const value of [-1, Number.NaN, Number.POSITIVE_INFINITY, Number.NEGATIVE_INFINITY, '4.99', null]) {
			expect(normalizeUsdStorePrice(value, 'USD')).toBeNull();
		}
		for (const currency of ['EUR', 'usd', '', null, undefined]) {
			expect(normalizeUsdStorePrice(4.99, currency)).toBeNull();
		}
	});

	test('keeps unavailable paid-store links without describing them as free', () => {
		const offers = buildSoftwareApplicationOffers({
			appStorePrice: null,
			playStorePrice: null
		});

		expect(offers.find(({ category }) => category === 'App Store')).toEqual({
			'@type': 'Offer',
			url: 'https://apps.apple.com/us/app/id6754315964',
			category: 'App Store'
		});
		expect(offers.find(({ category }) => category === 'Google Play')).toEqual({
			'@type': 'Offer',
			url: 'https://play.google.com/store/apps/details?id=com.edde746.plezy',
			category: 'Google Play'
		});
		expect(offers.filter(({ price }) => price === '0').map(({ category }) => category)).toEqual([
			'GitHub'
		]);
	});

	test('attaches valid USD prices to each paid mobile store', () => {
		const offers = buildSoftwareApplicationOffers({
			appStorePrice: '4.99',
			playStorePrice: '3.99'
		});

		expect(offers.find(({ category }) => category === 'App Store')).toMatchObject({
			price: '4.99',
			priceCurrency: 'USD'
		});
		expect(offers.find(({ category }) => category === 'Google Play')).toMatchObject({
			price: '3.99',
			priceCurrency: 'USD'
		});
	});
});

describe('route content contracts', () => {
	test('uses the same Watch Together answer in the visible FAQ and FAQ schema', () => {
		const visibleFaq = faqs.find(({ id }) => id === 'watch-together');
		expect(visibleFaq).toBeDefined();
		expect(visibleFaq?.answer).toBe(watchTogetherFaqAnswer);

		const schemaFaq = faqSchemaMainEntity.find(({ name }) => name === visibleFaq?.question);
		expect(schemaFaq).toBeDefined();
		expect(schemaFaq?.acceptedAnswer.text).toBe(watchTogetherFaqAnswer);
	});

	test('keeps the privacy route server-rendered without client hydration', () => {
		expect(privacyCsr).toBe(false);
	});
});
