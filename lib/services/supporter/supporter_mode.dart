/// How this build offers the Supporter perks: preset and custom themes and
/// alternate app icons.
///
/// Chosen per build with `--dart-define=SUPPORTER_MODE=<name>`. Leaving it unset
/// compiles the perks out.
enum SupporterMode {
  /// Perks compiled out: the GitHub iOS IPA and Android APK, and local builds.
  off,

  /// Perks unlock through the one-time Supporter purchase: App Store and Google Play.
  iap,

  /// Perks are free: Amazon Appstore, macOS and Linux.
  unlocked,

  /// Free inside a Microsoft Store (MSIX) install, hidden everywhere else. The
  /// GitHub Windows build is the same compile as the Store package, so only a
  /// runtime check can tell them apart.
  msstore,
}

const String _supporterModeDefine = String.fromEnvironment('SUPPORTER_MODE');

/// This build's [SupporterMode]. Const, so `off` builds tree-shake perk UI that
/// is guarded by a comparison against it.
const SupporterMode supporterBuildMode = _supporterModeDefine == 'iap'
    ? SupporterMode.iap
    : _supporterModeDefine == 'unlocked'
    ? SupporterMode.unlocked
    : _supporterModeDefine == 'msstore'
    ? SupporterMode.msstore
    : SupporterMode.off;

/// Whether this install shows the perks and how they unlock.
enum SupporterAvailability {
  /// No perk UI anywhere; a stored perk choice renders its default instead.
  hidden,

  /// Perks are usable without a purchase.
  free,

  /// Perks unlock through the Supporter in-app purchase.
  purchasable,
}

SupporterAvailability supporterAvailabilityFor(SupporterMode mode, {required bool isPackagedInstall}) => switch (mode) {
  SupporterMode.off => SupporterAvailability.hidden,
  SupporterMode.iap => SupporterAvailability.purchasable,
  SupporterMode.unlocked => SupporterAvailability.free,
  SupporterMode.msstore => isPackagedInstall ? SupporterAvailability.free : SupporterAvailability.hidden,
};
