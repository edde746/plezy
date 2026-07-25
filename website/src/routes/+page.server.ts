import type { PageServerLoad } from './$types';
import { loadHomepageStoreMetadata } from '$lib/server/homepage_store_metadata';

export const load: PageServerLoad = async ({ fetch }) =>
	loadHomepageStoreMetadata({
		fetch,
		loadPlayStoreListing: async () => {
			// Module initialization is optional external data and stays inside the
			// helper's Play Store failure boundary.
			const { default: gplay } = await import('google-play-scraper');
			return gplay.app({
				appId: 'com.edde746.plezy',
				country: 'us',
				lang: 'en'
			});
		}
	});
