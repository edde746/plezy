import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../i18n/app_locale_utils.dart';
import '../i18n/strings.g.dart';
import '../profiles/active_profile_provider.dart';
import '../providers/companion_remote_provider.dart';
import '../providers/download_provider.dart';
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
import 'trackers/tracker_constants.dart';
import 'trackers/trakt/trakt_tracker.dart';

/// One commit/effect path for settings widgets and typed callers. Existing
/// SettingsBindingOwner consumers (keyboard, theme, shaders) remain
/// the sole owners of their listener-driven effects.
class SettingsMutationService {
  const SettingsMutationService();

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
    final settings = SettingsService.instance;
    switch (pref.key) {
      case 'app_locale':
        final locale = settings.read(SettingsService.appLocale);
        await LocaleSettings.setLocale(locale);
        checkCurrent?.call();
        if (context.mounted) {
          context.read<MultiServerProvider?>()?.serverManager.updatePlexLanguage(locale.plexLanguageCode);
        }
      case 'force_tv_mode':
        TvDetectionService.setForceTVSync(settings.read(SettingsService.forceTvMode));
      case 'visual_effects':
        DevicePerformance.setOverrideSync(settings.read(SettingsService.visualEffects));
      case 'enable_discord_rpc':
        await DiscordRPCService.instance.setEnabled(settings.read(SettingsService.enableDiscordRPC));
      case 'music_volume':
        await context.read<MusicPlaybackService?>()?.setVolume(
          settings.read(SettingsService.musicVolume),
          persist: false,
        );
      case 'default_download_quality_preset':
        await context.read<DownloadProvider?>()?.reconcileAllDownloadQualities();
      case 'enable_trakt_scrobble':
        await TraktTracker.instance.setEnabled(settings.read(pref) as bool);
      case 'enable_companion_remote_server':
        final owner = context.read<CompanionRemoteProvider?>();
        if (owner == null) break;
        final enabled = settings.read(SettingsService.enableCompanionRemoteServer);
        if (enabled && context.read<ActiveProfileProvider?>()?.active == null) break;
        final applied = await applyCompanionRemoteServerSetting(context, enabled, checkCurrent: checkCurrent);
        checkCurrent?.call();
        if (!applied) throw StateError('The companion host could not apply the setting');
      case 'enable_trakt_watched_sync':
        await TraktTracker.instance.setWatchedSyncEnabled(settings.read(pref) as bool);
      case 'enable_mal_scrobble':
        await MalTracker.instance.setEnabled(settings.read(pref) as bool);
      case 'enable_anilist_scrobble':
        await AnilistTracker.instance.setEnabled(settings.read(pref) as bool);
      case 'enable_simkl_scrobble':
        await SimklTracker.instance.setEnabled(settings.read(pref) as bool);
      case 'enable_mdblist_scrobble':
        await MdblistTracker.instance.setEnabled(settings.read(pref) as bool);
    }
    checkCurrent?.call();
    if (rebuildRoot && needsRootRebuild(pref) && context.mounted) rebuild(context);
  }

  /// Bulk import/reset bypasses typed writes but must use the same effect
  /// owners. The snapshot is command-local and only avoids unnecessary rebuilds.
  static Object captureRootConfiguration() {
    final settings = SettingsService.instance;
    return (
      settings.read(SettingsService.appLocale),
      settings.read(SettingsService.forceTvMode),
      settings.read(SettingsService.visualEffects),
    );
  }

  Future<void> applyStoredEffects(BuildContext context, {required Object previousRootConfiguration}) async {
    final effectPrefs = <Pref<Object?>>[
      SettingsService.appLocale,
      SettingsService.forceTvMode,
      SettingsService.visualEffects,
      SettingsService.enableDiscordRPC,
      SettingsService.musicVolume,
      SettingsService.defaultDownloadQualityPreset,
      SettingsService.enableTraktWatchedSync,
      for (final service in TrackerService.values) SettingsService.scrobblePref(service),
      SettingsService.enableCompanionRemoteServer,
    ];
    for (final pref in effectPrefs) {
      if (!context.mounted) return;
      await applyEffects(context, pref, rebuildRoot: false);
    }
    if (context.mounted && previousRootConfiguration != captureRootConfiguration()) rebuild(context);
  }

  static bool needsRootRebuild(Pref<Object?> pref) =>
      pref == SettingsService.appLocale || pref == SettingsService.forceTvMode || pref == SettingsService.visualEffects;

  static void rebuild(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/', (route) => false);
  }
}
