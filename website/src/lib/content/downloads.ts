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

export const storeOptions = {
  ios: {
    id: 'app-store',
    label: 'App Store',
    url: 'https://apps.apple.com/us/app/id6754315964',
  },
  android: {
    id: 'play-store',
    label: 'Google Play',
    url: 'https://play.google.com/store/apps/details?id=com.edde746.plezy',
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

export const linuxArchitectures = [
  {
    label: 'x64 (Intel/AMD)',
    formats: [
      { label: '.deb (Debian/Ubuntu)', url: 'https://github.com/edde746/plezy/releases/latest/download/plezy-linux-x64.deb' },
      { label: '.rpm (Fedora/RHEL)', url: 'https://github.com/edde746/plezy/releases/latest/download/plezy-linux-x64.rpm' },
      { label: '.pkg.tar.zst (Arch)', url: 'https://github.com/edde746/plezy/releases/latest/download/plezy-linux-x64.pkg.tar.zst' },
      { label: '.tar.gz (Portable)', url: 'https://github.com/edde746/plezy/releases/latest/download/plezy-linux-x64.tar.gz' },
    ],
  },
  {
    label: 'ARM64',
    formats: [
      { label: '.deb (Debian/Ubuntu)', url: 'https://github.com/edde746/plezy/releases/latest/download/plezy-linux-arm64.deb' },
      { label: '.rpm (Fedora/RHEL)', url: 'https://github.com/edde746/plezy/releases/latest/download/plezy-linux-arm64.rpm' },
      { label: '.pkg.tar.zst (Arch)', url: 'https://github.com/edde746/plezy/releases/latest/download/plezy-linux-arm64.pkg.tar.zst' },
      { label: '.tar.gz (Portable)', url: 'https://github.com/edde746/plezy/releases/latest/download/plezy-linux-arm64.tar.gz' },
    ],
  },
] as const;
