import { describe, expect, test } from 'bun:test';
import { detectMobileStorePlatform, storeOptionsForPlatform } from '../src/lib/content/downloads';
import {
	buildSoftwareApplicationOffers,
	normalizeUsdStorePrice
} from '../src/lib/content/software_app_offers';

describe('mobile store selection', () => {
	test('routes browser evidence to the appropriate store buttons', () => {
		const cases = [
			{ evidence: {}, platform: 'unknown', storeIds: ['app-store', 'play-store'] },
			{
				evidence: { userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X)' },
				platform: 'ios',
				storeIds: ['app-store']
			},
			{
				evidence: { userAgent: 'Mozilla/5.0 (Linux; Android 15; Pixel 9)' },
				platform: 'android',
				storeIds: ['play-store']
			},
			{
				evidence: {
					userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)',
					platform: 'MacIntel',
					maxTouchPoints: 5
				},
				platform: 'ios',
				storeIds: ['app-store']
			},
			{
				evidence: {
					userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)',
					platform: 'MacIntel',
					maxTouchPoints: 0
				},
				platform: 'unknown',
				storeIds: ['app-store', 'play-store']
			}
		] as const;

		for (const { evidence, platform, storeIds } of cases) {
			const detected = detectMobileStorePlatform(evidence);
			expect(detected).toBe(platform);
			expect(storeOptionsForPlatform(detected).map(({ id }) => id)).toEqual(storeIds);
		}
	});
});

describe('store price normalization', () => {
	test('accepts only finite nonnegative USD amounts', () => {
		expect(normalizeUsdStorePrice(0, 'USD')).toBe('0');
		expect(normalizeUsdStorePrice(4.99, 'USD')).toBe('4.99');

		for (const value of [
			-1,
			Number.NaN,
			Number.POSITIVE_INFINITY,
			Number.NEGATIVE_INFINITY,
			'4.99',
			null
		]) {
			expect(normalizeUsdStorePrice(value, 'USD')).toBeNull();
		}
		for (const currency of ['EUR', 'usd', '', null, undefined]) {
			expect(normalizeUsdStorePrice(4.99, currency)).toBeNull();
		}
	});
});

describe('software application offers', () => {
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
