export type MobileStorePlatform = 'ios' | 'android' | 'unknown';

export type PlatformEvidence = {
  userAgent?: string;
  platform?: string;
  maxTouchPoints?: number;
};

export type StoreOption = {
  id: 'app-store' | 'play-store';
  label: string;
  url: string;
};

export const APP_STORE_ID = '6754315964';
export const ANDROID_PACKAGE = 'com.edde746.plezy';
export const AMAZON_URL = 'https://www.amazon.com/gp/product/B0GK65CVS1';

export const releaseAsset = (name: string) =>
  `https://github.com/edde746/plezy/releases/latest/download/${name}`;

export const storeOptions = {
  ios: {
    id: 'app-store',
    label: 'App Store',
    url: `https://apps.apple.com/us/app/id${APP_STORE_ID}`,
  },
  android: {
    id: 'play-store',
    label: 'Google Play',
    url: `https://play.google.com/store/apps/details?id=${ANDROID_PACKAGE}`,
  },
} as const satisfies Record<'ios' | 'android', StoreOption>;

export function detectMobileStorePlatform(evidence: PlatformEvidence = {}): MobileStorePlatform {
  const userAgent = evidence.userAgent?.toLowerCase() ?? '';
  const platform = evidence.platform?.toLowerCase() ?? '';

  if (/iphone|ipad|ipod/.test(userAgent)) return 'ios';
  if (/android/.test(userAgent)) return 'android';

  // iPadOS can request a desktop site and identify as MacIntel. Touch support
  // distinguishes it from a Mac without guessing from screen dimensions.
  if (platform === 'macintel' && (evidence.maxTouchPoints ?? 0) > 1) return 'ios';

  return 'unknown';
}

export function storeOptionsForPlatform(platform: MobileStorePlatform): readonly StoreOption[] {
  if (platform === 'ios') return [storeOptions.ios];
  if (platform === 'android') return [storeOptions.android];
  return [storeOptions.ios, storeOptions.android];
}

// Every architecture ships the same formats, so the menu is their cross product.
const LINUX_FORMATS = [
  { label: '.deb (Debian/Ubuntu)', extension: 'deb' },
  { label: '.rpm (Fedora/RHEL)', extension: 'rpm' },
  { label: '.pkg.tar.zst (Arch)', extension: 'pkg.tar.zst' },
  { label: '.tar.gz (Portable)', extension: 'tar.gz' },
];

export const linuxArchitectures = [
  { slug: 'x64', label: 'x64 (Intel/AMD)' },
  { slug: 'arm64', label: 'ARM64' },
].map(({ slug, label }) => ({
  label,
  formats: LINUX_FORMATS.map((format) => ({
    label: format.label,
    url: releaseAsset(`plezy-linux-${slug}.${format.extension}`),
  })),
}));
