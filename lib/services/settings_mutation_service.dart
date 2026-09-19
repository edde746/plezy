import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../i18n/app_locale_utils.dart';
import '../i18n/strings.g.dart';
import '../profiles/active_profile_provider.dart';
import '../providers/companion_remote_provider.dart';
import '../providers/multi_server_provider.dart';
import '../utils/platform_detector.dart';
import 'device_performance.dart';
import 'discord_rpc_service.dart';
import 'companion_remote/companion_remote_host_controller.dart';
import 'music/music_playback_service.dart';
import 'settings_service.dart';
import 'trackers/anilist/anilist_tracker.dart';
import 'trackers/mal/mal_tracker.dart';
import 'trackers/mdblist/mdblist_tracker.dart';
import 'trackers/simkl/simkl_tracker.dart';
import 'trackers/tracker.dart';
import 'trackers/tracker_constants.dart';
import 'trackers/trakt/trakt_tracker.dart';

/// Runtime effect of one stored pref. [checkCurrent] must be called after
/// every await so a profile switch mid-effect aborts the rest.
typedef _SettingsEffectHandler =
    Future<void> Function(BuildContext context, SettingsService settings, void Function()? checkCurrent);

class _SettingsEffect {
  final Pref<Object?> pref;
  final bool rebuildsRoot;
  final _SettingsEffectHandler apply;
  const _SettingsEffect(this.pref, this.apply, {this.rebuildsRoot = false});
}

/// One commit/effect path for settings widgets and typed callers. Existing
/// SettingsBindingOwner consumers (keyboard, theme, shaders) remain
/// the sole owners of their listener-driven effects.
class SettingsMutationService {
  const SettingsMutationService();

  /// Every pref with a runtime effect, in the order bulk import/reset replays
  /// them. Prefs without an entry are plain stored values.
  static final List<_SettingsEffect> _effects = [
    _SettingsEffect(SettingsService.appLocale, _applyAppLocale, rebuildsRoot: true),
    _SettingsEffect(
      SettingsService.forceTvMode,
      (_, settings, _) async => TvDetectionService.setForceTVSync(settings.read(SettingsService.forceTvMode)),
      rebuildsRoot: true,
    ),
    _SettingsEffect(
      SettingsService.visualEffects,
      (_, settings, _) async => DevicePerformance.setOverrideSync(settings.read(SettingsService.visualEffects)),
      rebuildsRoot: true,
    ),
    _SettingsEffect(
      SettingsService.enableDiscordRPC,
      (_, settings, _) => DiscordRPCService.instance.setEnabled(settings.read(SettingsService.enableDiscordRPC)),
    ),
    _SettingsEffect(SettingsService.musicVolume, (context, settings, _) async {
      await context.read<MusicPlaybackService?>()?.setVolume(
        settings.read(SettingsService.musicVolume),
        persist: false,
      );
    }),
    _SettingsEffect(
      SettingsService.enableTraktWatchedSync,
      (_, settings, _) =>
          TraktTracker.instance.setWatchedSyncEnabled(settings.read(SettingsService.enableTraktWatchedSync)),
    ),
    for (final service in TrackerService.values) _scrobbleEffect(service),
    _SettingsEffect(SettingsService.enableCompanionRemoteServer, _applyCompanionRemoteServer),
  ];

  /// [Pref] compares by identity and [SettingsService.scrobblePref] mints a
  /// fresh instance per call, so lookups go through the stable key.
  static final Map<String, _SettingsEffect> _effectsByKey = {for (final effect in _effects) effect.pref.key: effect};

  static _SettingsEffect _scrobbleEffect(TrackerService service) {
    final pref = SettingsService.scrobblePref(service);
    return _SettingsEffect(pref, (_, settings, _) => _trackerFor(service).setEnabled(settings.read(pref)));
  }

  static Tracker _trackerFor(TrackerService service) => switch (service) {
    TrackerService.mal => MalTracker.instance,
    TrackerService.anilist => AnilistTracker.instance,
    TrackerService.simkl => SimklTracker.instance,
    TrackerService.trakt => TraktTracker.instance,
    TrackerService.mdblist => MdblistTracker.instance,
  };

  static Future<void> _applyAppLocale(
    BuildContext context,
    SettingsService settings,
    void Function()? checkCurrent,
  ) async {
    final locale = settings.read(SettingsService.appLocale);
    await LocaleSettings.setLocale(locale);
    checkCurrent?.call();
    if (context.mounted) {
      context.read<MultiServerProvider?>()?.serverManager.updatePlexLanguage(locale.plexLanguageCode);
    }
  }

  static Future<void> _applyCompanionRemoteServer(
    BuildContext context,
    SettingsService settings,
    void Function()? checkCurrent,
  ) async {
    final owner = context.read<CompanionRemoteProvider?>();
    if (owner == null) return;
    final enabled = settings.read(SettingsService.enableCompanionRemoteServer);
    if (enabled && context.read<ActiveProfileProvider?>()?.active == null) return;
    final applied = await applyCompanionRemoteServerSetting(context, enabled, checkCurrent: checkCurrent);
    checkCurrent?.call();
    if (!applied) throw StateError('The companion host could not apply the setting');
  }

  Future<void> write<T>(
    BuildContext context,
    Pref<T> pref,
    T value, {
    bool reset = false,
    void Function()? checkCurrent,
    bool rebuildRoot = true,
  }) async {
    final settings = SettingsService.instance;
    if (!reset) SettingsService.validateEditableValue(pref, value);
    checkCurrent?.call();
    if (reset) {
      await settings.reset(pref, checkCurrent: checkCurrent);
    } else {
      await settings.write(pref, value, checkCurrent: checkCurrent);
    }
    checkCurrent?.call();
    if (!context.mounted) return;
    await applyEffects(context, pref, checkCurrent: checkCurrent, rebuildRoot: rebuildRoot);
  }

  Future<void> applyEffects(
    BuildContext context,
    Pref<Object?> pref, {
    void Function()? checkCurrent,
    bool rebuildRoot = true,
  }) async {
    checkCurrent?.call();
    final effect = _effectsByKey[pref.key];
    if (effect != null) await effect.apply(context, SettingsService.instance, checkCurrent);
    checkCurrent?.call();
    if (rebuildRoot && effect != null && effect.rebuildsRoot && context.mounted) rebuild(context);
  }

  /// Bulk import/reset bypasses typed writes but must use the same effect
  /// owners. The snapshot is command-local and only avoids unnecessary rebuilds.
  static List<Object?> captureRootConfiguration() {
    final settings = SettingsService.instance;
    return [
      for (final effect in _effects)
        if (effect.rebuildsRoot) settings.read(effect.pref),
    ];
  }

  Future<void> applyStoredEffects(BuildContext context, {required List<Object?> previousRootConfiguration}) async {
    for (final effect in _effects) {
      if (!context.mounted) return;
      await applyEffects(context, effect.pref, rebuildRoot: false);
    }
    if (context.mounted && !listEquals(previousRootConfiguration, captureRootConfiguration())) rebuild(context);
  }

  /// Whether writing the pref stored under [key] requires a root rebuild. Keyed
  /// so agent control can ask for resource keys that have no [Pref].
  static bool needsRootRebuild(String key) => _effectsByKey[key]?.rebuildsRoot ?? false;

  static void rebuild(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/', (route) => false);
  }
}
