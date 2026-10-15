import 'package:flutter/foundation.dart';

import '../../mixins/disposable_change_notifier_mixin.dart';
import '../../utils/platform_detector.dart';
import '../settings_service.dart';
import 'supporter_mode.dart';

/// App-lifetime owner of the Supporter entitlement, provided at the root
/// scope: a purchase belongs to the store account on this device, not to a
/// profile.
///
/// [isUnlocked] turns false only after a confirmed revocation (a refund), never
/// because the store is unreachable, so a listener may treat a true→false
/// transition as a real revocation.
class SupporterService extends ChangeNotifier with DisposableChangeNotifierMixin {
  SupporterService()
    : availability = supporterAvailabilityFor(
        supporterBuildMode,
        isPackagedInstall: PlatformDetector.isPackagedInstall(),
      );

  @visibleForTesting
  SupporterService.forTesting({required this.availability, this._purchased = false});

  /// Fixed for the life of the process.
  final SupporterAvailability availability;

  bool _purchased = false;

  /// Whether any perk UI is shown on this install.
  bool get isAvailable => availability != SupporterAvailability.hidden;

  /// Whether perks are usable right now.
  bool get isUnlocked => switch (availability) {
    SupporterAvailability.hidden => false,
    SupporterAvailability.free => true,
    SupporterAvailability.purchasable => _purchased,
  };

  /// Restores the last confirmed entitlement so perks render before the store answers.
  Future<void> init() async {
    if (availability != SupporterAvailability.purchasable) return;
    final settings = await SettingsService.getInstance();
    if (isDisposed) return;
    final cached = settings.read(SettingsService.supporterEntitlementCached);
    if (cached == _purchased) return;
    _purchased = cached;
    safeNotifyListeners();
  }

  /// [isUnlocked] for the pre-provider startup frame, from the same build
  /// policy and entitlement cache this service starts from.
  static bool startupUnlocked(SettingsService settings) =>
      switch (supporterAvailabilityFor(supporterBuildMode, isPackagedInstall: PlatformDetector.isPackagedInstall())) {
        SupporterAvailability.hidden => false,
        SupporterAvailability.free => true,
        SupporterAvailability.purchasable => settings.read(SettingsService.supporterEntitlementCached),
      };
}
