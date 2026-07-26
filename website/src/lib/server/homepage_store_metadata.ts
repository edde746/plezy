import { APP_STORE_ID } from '../content/downloads';
import { normalizeUsdStorePrice } from '../content/software_app_offers';

export type HomepageAggregateRating = {
	ratingValue: string;
	ratingCount: number;
};

export type HomepageStoreMetadata = {
	aggregateRating: HomepageAggregateRating | null;
	appStorePrice: string | null;
	playStorePrice: string | null;
};

export type HomepageStoreFetch = (url: string) => Promise<Response>;

export type PlayStoreListing = {
	available?: boolean;
	score?: number;
	ratings?: number;
	price?: unknown;
	currency?: unknown;
};

export type HomepageStoreMetadataDependencies = {
	fetch: HomepageStoreFetch;
	loadPlayStoreListing: () => Promise<PlayStoreListing>;
};

type StoreRating = {
	score: number;
	count: number;
};

type AppStoreLookupResult = {
	averageUserRating?: number;
	userRatingCount?: number;
	price?: unknown;
	currency?: unknown;
};

type AppStoreLookupResponse = {
	results?: AppStoreLookupResult[];
};

const APP_STORE_LOOKUP_URL = `https://itunes.apple.com/lookup?id=${APP_STORE_ID}`;

export async function loadHomepageStoreMetadata({
	fetch,
	loadPlayStoreListing
}: HomepageStoreMetadataDependencies): Promise<HomepageStoreMetadata> {
	let appStoreRating: StoreRating | null = null;
	let playStoreRating: StoreRating | null = null;
	let appStorePrice: string | null = null;
	let playStorePrice: string | null = null;

	try {
		const response = await fetch(APP_STORE_LOOKUP_URL);
		if (!response.ok) throw new Error(`App Store lookup failed: HTTP ${response.status}`);

		const data = (await response.json()) as AppStoreLookupResponse;
		const app = data.results?.[0];
		if (app?.averageUserRating && app.userRatingCount) {
			appStoreRating = {
				score: app.averageUserRating,
				count: app.userRatingCount
			};
		}
		appStorePrice = normalizeUsdStorePrice(app?.price, app?.currency);
	} catch {
		// App Store metadata is optional and must not suppress Play Store metadata.
	}

	try {
		const app = await loadPlayStoreListing();
		if (app.available === false) throw new Error('Google Play listing unavailable');
		if (app.score && app.ratings) {
			playStoreRating = {
				score: app.score,
				count: app.ratings
			};
		}
		playStorePrice = normalizeUsdStorePrice(app.price, app.currency);
	} catch {
		// Play Store metadata is optional and must not suppress App Store metadata.
	}

	const ratings = [appStoreRating, playStoreRating].filter(
		(rating): rating is StoreRating => rating !== null
	);
	const aggregateRating = aggregateStoreRatings(ratings);

	return { aggregateRating, appStorePrice, playStorePrice };
}

function aggregateStoreRatings(ratings: readonly StoreRating[]): HomepageAggregateRating | null {
	if (ratings.length === 0) return null;

	const ratingCount = ratings.reduce((sum, rating) => sum + rating.count, 0);
	const weightedSum = ratings.reduce((sum, rating) => sum + rating.score * rating.count, 0);
	return {
		ratingValue: (weightedSum / ratingCount).toFixed(1),
		ratingCount
	};
}
