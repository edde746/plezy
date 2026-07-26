import { AMAZON_URL, storeOptions } from './downloads';

export type StorePrices = {
  appStorePrice: string | null;
  playStorePrice: string | null;
};

export type SoftwareApplicationOffer = {
  '@type': 'Offer';
  url: string;
  category: string;
  price?: string;
  priceCurrency?: 'USD';
};

export function normalizeUsdStorePrice(value: unknown, currency: unknown): string | null {
  if (typeof value !== 'number' || !Number.isFinite(value) || value < 0 || currency !== 'USD') return null;
  return String(value);
}

export function buildSoftwareApplicationOffers({
  appStorePrice,
  playStorePrice,
}: StorePrices): SoftwareApplicationOffer[] {
  return [
    {
      '@type': 'Offer',
      url: storeOptions.ios.url,
      category: 'App Store',
      ...(appStorePrice === null
        ? {}
        : {
            price: appStorePrice,
            priceCurrency: 'USD' as const,
          }),
    },
    {
      '@type': 'Offer',
      url: storeOptions.android.url,
      category: 'Google Play',
      ...(playStorePrice === null
        ? {}
        : {
            price: playStorePrice,
            priceCurrency: 'USD' as const,
          }),
    },
    {
      '@type': 'Offer',
      url: AMAZON_URL,
      category: 'Amazon Appstore',
    },
    {
      '@type': 'Offer',
      url: 'https://github.com/edde746/plezy',
      price: '0',
      priceCurrency: 'USD',
      category: 'GitHub',
    },
  ];
}
