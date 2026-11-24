import 'package:collection/collection.dart';

import '../services/settings_service.dart';
import 'active_profile_provider.dart';

extension ProfileSelectionPolicy on ActiveProfileProvider {
  /// The "ask for a profile every time the app opens" rule: the pref only bites
  /// when there is more than one profile to pick from.
  ///
  /// Stated once because the sites must agree — ActiveProfileBinder defers its
  /// cold-start bind exactly when this holds, and SetupScreen/MainScreen pop the
  /// picker exactly when it holds. If they drifted, the binder would defer a bind
  /// that nothing ever prompts for and the user would land on an unbound screen.
  bool requiresSelectionOnOpen(SettingsService settings) =>
      settings.read(SettingsService.requireProfileSelectionOnOpen) && hasMultipleProfiles;

  /// Whether [profileId]'s Continue Watching may appear on the launcher shelf
  /// (Android TV Watch Next, tvOS Top Shelf), which anyone at the TV sees
  /// without opening the app. Opening the app asks for a profile, and so for
  /// its PIN, exactly when [requiresSelectionOnOpen] holds; the shelf must not
  /// show a protected profile past that gate. Otherwise the app reopens
  /// straight into the active profile, so the shelf shows nothing opening the
  /// app would not. An unknown profile stays off.
  bool mayPublishToSystemShelf(String profileId, SettingsService settings) {
    final profile = profiles.firstWhereOrNull((p) => p.id == profileId);
    if (profile == null) return false;
    return !profile.isPinProtected || !requiresSelectionOnOpen(settings);
  }
}
