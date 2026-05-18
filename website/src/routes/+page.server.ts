import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ fetch }) => {
	let appStoreRating: { score: number; count: number } | null = null;
	let playStoreRating: { score: number; count: number } | null = null;
	let appStorePrice: string | null = null;
	let playStorePrice: string | null = null;

	try {
		const res = await fetch('https://itunes.apple.com/lookup?id=6754315964');
		const data = await res.json();
		const app = data.results?.[0];
		if (app?.averageUserRating && app?.userRatingCount) {
			appStoreRating = {
				score: app.averageUserRating,
				count: app.userRatingCount
			};
		}
		if (app?.price != null) {
			appStorePrice = String(app.price);
		}
	} catch {
		// App Store fetch failed, continue without it
	}

	try {
		const gplay = await import('google-play-scraper');
		const app = await gplay.default.app({ appId: 'com.edde746.plezy' });
		if (app.score && app.ratings) {
			playStoreRating = {
				score: app.score,
				count: app.ratings
			};
		}
		if (app.price != null) {
			playStorePrice = String(app.price);
		}
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
