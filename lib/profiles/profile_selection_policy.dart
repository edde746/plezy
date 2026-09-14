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
}
