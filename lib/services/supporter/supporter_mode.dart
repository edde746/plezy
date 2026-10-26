/// How this build offers PlezyNG's full-app access: a seven-day trial followed
/// by a one-time lifetime unlock in store builds.
///
/// Chosen per build with `--dart-define=SUPPORTER_MODE=<name>`. Leaving it unset
/// compiles the perks out.
enum SupporterMode {
  /// Store access is not compiled in: developer artifacts and local builds.
  off,

  /// Full access uses a seven-day trial and the one-time lifetime purchase.
  iap,

  /// Full access is free in builds configured for free unlocks.
  unlocked,
}

const String _supporterModeDefine = String.fromEnvironment('SUPPORTER_MODE');

/// This build's [SupporterMode]. Const, so `off` builds tree-shake perk UI that
/// is guarded by a comparison against it.
const SupporterMode supporterBuildMode = _supporterModeDefine == 'iap'
    ? SupporterMode.iap
    : _supporterModeDefine == 'unlocked'
    ? SupporterMode.unlocked
    : SupporterMode.off;

/// Whether this install applies store access rules.
enum SupporterAvailability {
  /// No store paywall; intended for developer artifacts and local builds.
  hidden,

  /// Access is free.
  free,

  /// Access uses the trial and lifetime in-app purchase.
  purchasable,
}

SupporterAvailability supporterAvailabilityFor(SupporterMode mode) => switch (mode) {
  SupporterMode.off => SupporterAvailability.hidden,
  SupporterMode.iap => SupporterAvailability.purchasable,
  SupporterMode.unlocked => SupporterAvailability.free,
};
