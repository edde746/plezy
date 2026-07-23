import type { PageServerLoad } from './$types';
import { normalizeUsdStorePrice } from '$lib/content/software_app_offers';

export const load: PageServerLoad = async ({ fetch }) => {
	let appStoreRating: { score: number; count: number } | null = null;
	let playStoreRating: { score: number; count: number } | null = null;
	let appStorePrice: string | null = null;
	let playStorePrice: string | null = null;

	try {
		const res = await fetch('https://itunes.apple.com/lookup?id=6754315964');
		if (!res.ok) throw new Error(`App Store lookup failed: HTTP ${res.status}`);
		const data = await res.json();
		const app = data.results?.[0];
		if (app?.averageUserRating && app?.userRatingCount) {
			appStoreRating = {
				score: app.averageUserRating,
				count: app.userRatingCount
			};
		}
		appStorePrice = normalizeUsdStorePrice(app?.price, app?.currency);
	} catch {
		// App Store fetch failed, continue without it
	}

	try {
		// Module initialization is optional external data and must stay inside this failure boundary.
		const { default: gplay } = await import('google-play-scraper');
		const app = await gplay.app({
			appId: 'com.edde746.plezy',
			country: 'us',
			lang: 'en'
		});
		if (app.available === false) throw new Error('Google Play listing unavailable');
		if (app.score && app.ratings) {
			playStoreRating = {
				score: app.score,
				count: app.ratings
			};
		}
		playStorePrice = normalizeUsdStorePrice(app.price, app.currency);
	} catch {
		// Play Store fetch failed, continue without it
	}

	// Compute combined weighted average
	let aggregateRating: { ratingValue: string; ratingCount: number } | null = null;
	const ratings = [appStoreRating, playStoreRating].filter(Boolean) as {
		score: number;
		count: number;
	}[];
	if (ratings.length > 0) {
		const totalCount = ratings.reduce((sum, r) => sum + r.count, 0);
		const weightedSum = ratings.reduce((sum, r) => sum + r.score * r.count, 0);
		aggregateRating = {
			ratingValue: (weightedSum / totalCount).toFixed(1),
			ratingCount: totalCount
		};
	}

	return { aggregateRating, appStorePrice, playStorePrice };
};
