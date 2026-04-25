import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import '../models/hotkey_model.dart';
import 'image_cache_service.dart';
import 'package:plezy/utils/app_logger.dart';
import '../i18n/strings.g.dart';
import '../models/mpv_config_models.dart';
import '../models/external_player_models.dart';
import 'base_shared_preferences_service.dart';
export 'base_shared_preferences_service.dart'
    show Pref, BoolPref, IntPref, DoublePref, StringPref, NullableStringPref, StringListPref, EnumPref, JsonPref;
import '../utils/platform_detector.dart';
import 'trackers/tracker_constants.dart';

enum ThemeMode { system, light, dark, oled }

/// Library density is now an int 1–5 (1 = most compact, 5 = most comfortable).
/// Default is 3.
class LibraryDensity {
  static const int min = 1;
  static const int max = 5;
  static const int defaultValue = 3;

  /// Returns a 0.0–1.0 factor for interpolation (0 = most compact, 1 = most comfortable).
  static double factor(int density) => (density.clamp(min, max) - min) / (max - min);
}

enum ViewMode { grid, list }

enum EpisodePosterMode { seriesPoster, seasonPoster, episodeThumbnail }

enum SubAssOverride { no, yes, scale, force, strip }

const String _bufferSizeMigratedKey = 'buffer_size_migrated_to_auto';
const String _legacyUseSeasonPosterKey = 'use_season_poster';
const String _legacyMpvConfigEntriesKey = 'mpv_config_entries';

/// One-time auto-reset migration for buffer size.
class _BufferSizePref extends IntPref {
  const _BufferSizePref() : super('buffer_size');

  @override
  int readFrom(BaseSharedPreferencesService svc) {
    // SharedPreferences updates in-memory cache synchronously, so the
    // unawaited disk-flush futures are safe here (idempotent if re-run).
    if (svc.prefs.getBool(_bufferSizeMigratedKey) != true) {
      svc.prefs.remove(key);
      svc.prefs.setBool(_bufferSizeMigratedKey, true);
    }
    return super.readFrom(svc);
  }
}

/// Migrates from the legacy enum-string format and clamps to 1..5.
class _LibraryDensityPref extends Pref<int> {
  const _LibraryDensityPref() : super('library_density');

  @override
  int readFrom(BaseSharedPreferencesService svc) {
    try {
      final intVal = svc.prefs.getInt(key);
      if (intVal != null) return intVal.clamp(LibraryDensity.min, LibraryDensity.max);
    } on TypeError {
      // Stored value is a String from old enum format — fall through to migration.
    }
    String? strVal;
    try {
      strVal = svc.prefs.getString(key);
    } on TypeError {
      // Value exists but isn't a String either.
    }
    final result = switch (strVal) {
      'compact' => 2,
      'comfortable' => 4,
      _ => LibraryDensity.defaultValue,
    };
    svc.prefs.setInt(key, result);
    return result;
  }

  @override
  Future<void> writeTo(BaseSharedPreferencesService svc, int value) =>
      svc.writeInt(key, value.clamp(LibraryDensity.min, LibraryDensity.max));
}

/// Migrates from the legacy `use_season_poster` boolean key.
class _EpisodePosterModePref extends EnumPref<EpisodePosterMode> {
  const _EpisodePosterModePref()
    : super('episode_poster_mode', values: EpisodePosterMode.values, defaultValue: EpisodePosterMode.episodeThumbnail);

  @override
  EpisodePosterMode readFrom(BaseSharedPreferencesService svc) {
    final legacyValue = svc.prefs.getBool(_legacyUseSeasonPosterKey);
    if (legacyValue != null) {
      final migrated = legacyValue ? EpisodePosterMode.seasonPoster : EpisodePosterMode.seriesPoster;
      svc.prefs.remove(_legacyUseSeasonPosterKey);
      svc.prefs.setString(key, migrated.name);
      return migrated;
    }
    return super.readFrom(svc);
  }
}

/// Stored as the language code; null/empty falls back to the device locale.
class _AppLocalePref extends Pref<AppLocale> {
  const _AppLocalePref() : super('app_locale');

  @override
  AppLocale readFrom(BaseSharedPreferencesService svc) {
    final code = svc.prefs.getString(key);
    if (code == null || code.isEmpty) return AppLocaleUtils.findDeviceLocale();
    return AppLocale.values.asNameMap()[code] ?? AppLocale.en;
  }

  @override
  Future<void> writeTo(BaseSharedPreferencesService svc, AppLocale value) => svc.writeString(key, value.languageCode);
}

/// Mobile-only with a macOS-disabled-by-default rule; forced off on TV and non-mobile platforms.
class _AutoPipPref extends Pref<bool> {
  const _AutoPipPref() : super('auto_pip');

  @override
  bool readFrom(BaseSharedPreferencesService svc) {
    if (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS) return false;
    if (PlatformDetector.isTV()) return false;
    return svc.prefs.getBool(key) ?? !Platform.isMacOS;
  }

  @override
  Future<void> writeTo(BaseSharedPreferencesService svc, bool value) => svc.writeBool(key, value);
}

String? _trimEmptyAsNull(String? v) {
  final t = v?.trim();
  return (t == null || t.isEmpty) ? null : t;
}

String _legacyMpvEntriesToText(List<dynamic> entries) {
  final lines = <String>[];
  for (final item in entries) {
    if (item is Map<String, dynamic>) {
      final k = item['key'] as String? ?? '';
      final v = item['value'] as String? ?? '';
      final enabled = item['isEnabled'] as bool? ?? true;
      if (k.isNotEmpty) {
        lines.add(enabled ? '$k=$v' : '#$k=$v');
      }
    }
  }
  return lines.join('\n');
}

class _MpvConfigTextPref extends StringPref {
  const _MpvConfigTextPref() : super('mpv_config_text');

  @override
  String readFrom(BaseSharedPreferencesService svc) {
    final text = svc.prefs.getString(key);
    if (text != null) return text;

    final legacyJson = svc.prefs.getString(_legacyMpvConfigEntriesKey);
    if (legacyJson == null) return '';

    try {
      final migrated = _legacyMpvEntriesToText(json.decode(legacyJson) as List<dynamic>);
      svc.prefs.setString(key, migrated);
      return migrated;
    } catch (e, st) {
      appLogger.w('SettingsService: failed to migrate mpv config', error: e, stackTrace: st);
      return '';
    }
  }
}

List<MpvPreset> _decodeMpvPresets(dynamic raw) {
  return (raw as List).map((e) {
    final map = e as Map<String, dynamic>;
    if (map.containsKey('entries') && !map.containsKey('text')) {
      map['text'] = _legacyMpvEntriesToText(map['entries'] as List);
    }
    return MpvPreset.fromJson(map);
  }).toList();
}

Map<String, String> _defaultKeyboardShortcuts() => {
  'play_pause': 'Space',
  'volume_up': 'Arrow Up',
  'volume_down': 'Arrow Down',
  'seek_forward': 'Arrow Right',
  'seek_backward': 'Arrow Left',
  'seek_forward_large': 'Shift+Arrow Right',
  'seek_backward_large': 'Shift+Arrow Left',
  'fullscreen_toggle': 'F',
  'mute_toggle': 'M',
  'subtitle_toggle': 'S',
  'audio_track_next': 'A',
  'subtitle_track_next': 'Shift+S',
  'chapter_next': 'N',
  'chapter_previous': 'P',
  'speed_increase': 'Plus',
  'speed_decrease': 'Minus',
  'speed_reset': 'R',
  'sub_seek_next': 'Ctrl+Right',
  'sub_seek_prev': 'Ctrl+Left',
};

Map<String, HotKey> _defaultKeyboardHotkeys() => {
  'play_pause': const HotKey(key: PhysicalKeyboardKey.space),
  'volume_up': const HotKey(key: PhysicalKeyboardKey.arrowUp),
  'volume_down': const HotKey(key: PhysicalKeyboardKey.arrowDown),
  'seek_forward': const HotKey(key: PhysicalKeyboardKey.arrowRight),
  'seek_backward': const HotKey(key: PhysicalKeyboardKey.arrowLeft),
  'seek_forward_large': const HotKey(key: PhysicalKeyboardKey.arrowRight, modifiers: [HotKeyModifier.shift]),
  'seek_backward_large': const HotKey(key: PhysicalKeyboardKey.arrowLeft, modifiers: [HotKeyModifier.shift]),
  'fullscreen_toggle': const HotKey(key: PhysicalKeyboardKey.keyF),
  'mute_toggle': const HotKey(key: PhysicalKeyboardKey.keyM),
  'subtitle_toggle': const HotKey(key: PhysicalKeyboardKey.keyS),
  'audio_track_next': const HotKey(key: PhysicalKeyboardKey.keyA),
  'subtitle_track_next': const HotKey(key: PhysicalKeyboardKey.keyS, modifiers: [HotKeyModifier.shift]),
  'chapter_next': const HotKey(key: PhysicalKeyboardKey.keyN),
  'chapter_previous': const HotKey(key: PhysicalKeyboardKey.keyP),
  'episode_next': const HotKey(key: PhysicalKeyboardKey.keyN, modifiers: [HotKeyModifier.shift]),
  'episode_previous': const HotKey(key: PhysicalKeyboardKey.keyP, modifiers: [HotKeyModifier.shift]),
  'speed_increase': const HotKey(key: PhysicalKeyboardKey.equal),
  'speed_decrease': const HotKey(key: PhysicalKeyboardKey.minus),
  'speed_reset': const HotKey(key: PhysicalKeyboardKey.keyR),
  'sub_seek_next': const HotKey(key: PhysicalKeyboardKey.arrowRight, modifiers: [HotKeyModifier.control]),
  'sub_seek_prev': const HotKey(key: PhysicalKeyboardKey.arrowLeft, modifiers: [HotKeyModifier.control]),
  'shader_toggle': const HotKey(key: PhysicalKeyboardKey.keyG),
  'skip_marker': const HotKey(key: PhysicalKeyboardKey.enter),
};

Map<String, String> _decodeKeyboardShortcuts(dynamic raw) {
  final stored = (raw as Map<String, dynamic>).map((k, v) => MapEntry(k, v.toString()));
  // Merge with defaults so newly-added defaults appear without resetting customizations.
  return {..._defaultKeyboardShortcuts(), ...stored};
}

Map<String, HotKey> _decodeKeyboardHotkeys(dynamic raw) {
  final result = <String, HotKey>{};
  for (final entry in (raw as Map<String, dynamic>).entries) {
    final hk = SettingsService.deserializeHotKey(entry.value as Map<String, dynamic>);
    if (hk != null) result[entry.key] = hk;
  }
  return {..._defaultKeyboardHotkeys(), ...result};
}

class SettingsService extends BaseSharedPreferencesService {
  static const String defaultIntroPattern = r'(?:^|\b)(?:intro(?:duction)?|opening)(?:\b|$)|^op(?:\s?\d+)?$';
  static const String defaultCreditsPattern = r'(?:^|\b)(?:outro|closing|credits?|ending)(?:\b|$)|^ed(?:\s?\d+)?$';

  static const enableDebugLogging = BoolPref('enable_debug_logging', onWrite: setLoggerLevel);
  static const crashReporting = BoolPref('crash_reporting', defaultValue: true);
  static const enableHardwareDecoding = BoolPref('enable_hardware_decoding', defaultValue: true);
  static const enableHDR = BoolPref('enable_hdr', defaultValue: true);
  static const preferredVideoCodec = StringPref('preferred_video_codec', defaultValue: 'auto');
  static const preferredAudioCodec = StringPref('preferred_audio_codec', defaultValue: 'auto');
  static const viewMode = EnumPref<ViewMode>('view_mode', values: ViewMode.values, defaultValue: ViewMode.grid);
  static const seekTimeSmall = IntPref('seek_time_small', defaultValue: 10);
  static const seekTimeLarge = IntPref('seek_time_large', defaultValue: 30);
  static const rewindOnResume = IntPref('rewind_on_resume');
  static const showHeroSection = BoolPref('show_hero_section', defaultValue: true);
  static const useGlobalHubs = BoolPref('use_global_hubs', defaultValue: true);
  static const showServerNameOnHubs = BoolPref('show_server_name_on_hubs');
  static const groupLibrariesByServer = BoolPref('group_libraries_by_server', defaultValue: true);
  static const sleepTimerDuration = IntPref('sleep_timer_duration', defaultValue: 30);
  static const audioSyncOffset = IntPref('audio_sync_offset');
  static const subtitleSyncOffset = IntPref('subtitle_sync_offset');
  static const volume = DoublePref('volume', defaultValue: 100.0);
  static const rotationLocked = BoolPref('rotation_locked', defaultValue: true);
  static const subtitleFontSize = IntPref('subtitle_font_size', defaultValue: 38);
  static const subtitleTextColor = StringPref('subtitle_text_color', defaultValue: '#FFFFFF');
  static const subtitleBorderSize = IntPref('subtitle_border_size', defaultValue: 3);
  static const subtitleBorderColor = StringPref('subtitle_border_color', defaultValue: '#000000');
  static const subtitleBackgroundColor = StringPref('subtitle_background_color', defaultValue: '#000000');
  static const subtitleBackgroundOpacity = IntPref('subtitle_background_opacity');
  static const subAssOverride = EnumPref<SubAssOverride>(
    'sub_ass_override',
    values: SubAssOverride.values,
    defaultValue: SubAssOverride.no,
  );
  static const subtitleBold = BoolPref('subtitle_bold');
  static const subtitleItalic = BoolPref('subtitle_italic');
  static const rememberTrackSelections = BoolPref('remember_track_selections', defaultValue: true);
  static const clickVideoTogglesPlayback = BoolPref('click_video_toggles_playback');
  static const autoSkipIntro = BoolPref('auto_skip_intro');
  static const autoSkipCredits = BoolPref('auto_skip_credits');
  static const autoSkipDelay = IntPref('auto_skip_delay', defaultValue: 5);
  static const introPattern = StringPref('intro_pattern', defaultValue: defaultIntroPattern);
  static const creditsPattern = StringPref('credits_pattern', defaultValue: defaultCreditsPattern);
  static const customDownloadPathType = NullableStringPref('custom_download_path_type');
  static const downloadOnWifiOnly = BoolPref('download_on_wifi_only');
  static const autoRemoveWatchedDownloads = BoolPref('auto_remove_watched_downloads');
  static const autoCheckUpdatesOnStartup = BoolPref('auto_check_updates_on_startup', defaultValue: true);
  static const showPerformanceOverlay = BoolPref('show_performance_overlay');
  static const autoHidePerformanceOverlay = BoolPref('auto_hide_performance_overlay', defaultValue: true);
  static const enableDiscordRPC = BoolPref('enable_discord_rpc');
  static const enableTraktScrobble = BoolPref('enable_trakt_scrobble', defaultValue: true);
  static const enableTraktWatchedSync = BoolPref('enable_trakt_watched_sync', defaultValue: true);
  static const enableMalScrobble = BoolPref('enable_mal_scrobble', defaultValue: true);
  static const enableAnilistScrobble = BoolPref('enable_anilist_scrobble', defaultValue: true);
  static const enableSimklScrobble = BoolPref('enable_simkl_scrobble', defaultValue: true);
  static const matchContentFrameRate = BoolPref('match_content_frame_rate');
  static const tunneledPlayback = BoolPref('tunneled_playback', defaultValue: true);
  static const defaultQualityPreset = StringPref('default_quality_preset', defaultValue: 'original');
  static const autoPlayNextEpisode = BoolPref('auto_play_next_episode', defaultValue: true);
  static const useExoPlayer = BoolPref('use_exoplayer', defaultValue: true);
  static const alwaysKeepSidebarOpen = BoolPref('always_keep_sidebar_open');
  static const showUnwatchedCount = BoolPref('show_unwatched_count', defaultValue: true);
  static const showEpisodeNumberOnCards = BoolPref('show_episode_number_on_cards', defaultValue: true);
  static const hideSpoilers = BoolPref('hide_spoilers');
  static const showNavBarLabels = BoolPref('show_nav_bar_labels', defaultValue: true);
  static const globalShaderPreset = StringPref('global_shader_preset', defaultValue: 'none');
  static const requireProfileSelectionOnOpen = BoolPref('require_profile_selection_on_open');
  static const useExternalPlayer = BoolPref('use_external_player');
  static const confirmExitOnBack = BoolPref('confirm_exit_on_back', defaultValue: true);
  static const forceTvMode = BoolPref('force_tv_mode');
  static const ambientLighting = BoolPref('ambient_lighting');
  static const audioPassthrough = BoolPref('audio_passthrough');
  static const audioNormalization = BoolPref('audio_normalization');
  static const liveTvDefaultFavorites = BoolPref('live_tv_default_favorites');
  static const matchRefreshRate = BoolPref('match_refresh_rate');
  static const matchDynamicRange = BoolPref('match_dynamic_range');
  static const appLocale = _AppLocalePref();
  static const autoPip = _AutoPipPref();
  static const customDownloadPath = NullableStringPref('custom_download_path');
  static final customRelayUrl = NullableStringPref('custom_relay_url', transform: _trimEmptyAsNull);
  static const recentRooms = NullableStringPref('watch_together_recent_rooms');

  static final maxVolume = IntPref('max_volume', defaultValue: 100, transform: (v) => v.clamp(100, 300));
  static final subtitlePosition = IntPref('subtitle_position', defaultValue: 100, transform: (v) => v.clamp(0, 100));
  static final defaultPlaybackSpeed = DoublePref(
    'default_playback_speed',
    defaultValue: 1.0,
    transform: (v) => v.clamp(0.5, 3.0),
  );
  static final defaultBoxFitMode = IntPref('default_box_fit_mode', transform: (v) => v.clamp(0, 2));
  static final displaySwitchDelay = IntPref('display_switch_delay', transform: (v) => v.clamp(0, 10));

  static final themeMode = EnumPref<ThemeMode>(
    'theme_mode',
    values: ThemeMode.values,
    defaultValue: TvDetectionService.isTVSync() ? ThemeMode.oled : ThemeMode.system,
  );
  static final videoPlayerNavigationEnabled = BoolPref(
    'video_player_navigation_enabled',
    defaultValue: TvDetectionService.isTVSync(),
  );
  static final enableCompanionRemoteServer = BoolPref(
    'enable_companion_remote_server',
    defaultValue: PlatformDetector.isDesktopOS(),
  );

  static const bufferSize = _BufferSizePref();
  static const libraryDensity = _LibraryDensityPref();
  static const episodePosterMode = _EpisodePosterModePref();
  static const mpvConfigText = _MpvConfigTextPref();

  static final keyboardShortcuts = JsonPref<Map<String, String>>(
    'keyboard_shortcuts',
    defaultValue: _defaultKeyboardShortcuts(),
    encode: json.encode,
    decode: _decodeKeyboardShortcuts,
  );
  static final keyboardHotkeys = JsonPref<Map<String, HotKey>>(
    'keyboard_hotkeys',
    defaultValue: _defaultKeyboardHotkeys(),
    encode: (v) => json.encode(v.map((k, hk) => MapEntry(k, SettingsService.serializeHotKey(hk)))),
    decode: _decodeKeyboardHotkeys,
  );
  static final mediaVersionPreferences = JsonPref<Map<String, int>>(
    'media_version_preferences',
    defaultValue: const {},
    encode: json.encode,
    decode: (raw) => (raw as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int)),
  );
  static final customShaderPresets = JsonPref<List<Map<String, dynamic>>>(
    'custom_shader_presets',
    defaultValue: const [],
    encode: json.encode,
    decode: (raw) => (raw as List).cast<Map<String, dynamic>>(),
  );
  static final selectedExternalPlayer = JsonPref<ExternalPlayer>(
    'selected_external_player',
    defaultValue: KnownPlayers.systemDefault,
    encode: (p) => json.encode(p.toJson()),
    decode: (raw) => ExternalPlayer.fromJson(raw as Map<String, dynamic>),
  );
  static final customExternalPlayers = JsonPref<List<ExternalPlayer>>(
    'custom_external_players',
    defaultValue: const [],
    encode: (v) => json.encode(v.map((p) => p.toJson()).toList()),
    decode: (raw) => (raw as List).map((e) => ExternalPlayer.fromJson(e as Map<String, dynamic>)).toList(),
  );
  static final mpvPresets = JsonPref<List<MpvPreset>>(
    'mpv_config_presets',
    defaultValue: const [],
    encode: (v) => json.encode(v.map((p) => p.toJson()).toList()),
    decode: _decodeMpvPresets,
  );

  static IntPref watchedThresholdPref(String serverId) => IntPref('watched_threshold_$serverId', defaultValue: 90);

  static EnumPref<TrackerLibraryFilterMode> trackerFilterModePref(TrackerService s) => EnumPref(
    'tracker_library_filter_mode_${s.name}',
    values: TrackerLibraryFilterMode.values,
    defaultValue: TrackerLibraryFilterMode.blacklist,
  );

  static StringListPref trackerFilterIdsPref(TrackerService s) =>
      StringListPref('tracker_library_filter_ids_${s.name}');

  SettingsService._();

  static SettingsService? _cachedInstance;

  static Future<SettingsService> getInstance() async {
    _cachedInstance ??= await BaseSharedPreferencesService.initializeInstance(() => SettingsService._());
    return _cachedInstance!;
  }

  /// Synchronous access to the singleton, or null if not yet initialized.
  static SettingsService? get instanceOrNull => _cachedInstance;

  /// Drop the cached singleton so the next [getInstance] call rebuilds against
  /// the current SharedPreferences state. Test-only — pair with
  /// [BaseSharedPreferencesService.resetForTesting].
  @visibleForTesting
  static void resetForTesting() {
    _cachedInstance = null;
  }

  static Map<String, String> defaultKeyboardShortcuts() => _defaultKeyboardShortcuts();
  static Map<String, HotKey> defaultKeyboardHotkeys() => _defaultKeyboardHotkeys();

  /// Null keys bypass the filter so we err on the side of syncing.
  bool isLibraryAllowedForTracker(TrackerService service, String? libraryGlobalKey) {
    if (libraryGlobalKey == null) return true;
    final inList = read(trackerFilterIdsPref(service)).contains(libraryGlobalKey);
    final mode = read(trackerFilterModePref(service));
    return mode == TrackerLibraryFilterMode.blacklist ? !inList : inList;
  }

  Future<void> removeCustomExternalPlayer(String id) async {
    final players = read(customExternalPlayers).where((p) => p.id != id).toList();
    await write(customExternalPlayers, players);
    if (read(selectedExternalPlayer).id == id) {
      await write(selectedExternalPlayer, KnownPlayers.systemDefault);
    }
  }

  /// Parse raw config text into a `Map<String, String>` (skip blanks and # comments).
  static Map<String, String> parseMpvConfigText(String text) {
    final result = <String, String>{};
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final eqIndex = trimmed.indexOf('=');
      if (eqIndex <= 0) continue;
      final k = trimmed.substring(0, eqIndex).trim();
      final v = trimmed.substring(eqIndex + 1).trim();
      if (k.isNotEmpty) result[k] = v;
    }
    return result;
  }

  /// Save a new preset (overwrites existing with same name).
  Future<void> saveMpvPreset(String name, String text) async {
    final presets = read(mpvPresets).where((p) => p.name != name).toList();
    presets.add(MpvPreset(name: name, text: text, createdAt: DateTime.now()));
    await write(mpvPresets, presets);
  }

  Future<void> deleteMpvPreset(String name) async {
    final presets = read(mpvPresets).where((p) => p.name != name).toList();
    await write(mpvPresets, presets);
  }

  /// Load a preset (replaces current config text).
  Future<void> loadMpvPreset(String name) async {
    final presets = read(mpvPresets);
    final preset = presets.firstWhere((p) => p.name == name, orElse: () => throw Exception('Preset not found: $name'));
    await write(mpvConfigText, preset.text);
  }

  static const _modifierMap = <String, HotKeyModifier>{
    'alt': HotKeyModifier.alt,
    'control': HotKeyModifier.control,
    'shift': HotKeyModifier.shift,
    'meta': HotKeyModifier.meta,
    'capsLock': HotKeyModifier.capsLock,
    'fn': HotKeyModifier.fn,
  };

  static Map<String, dynamic> serializeHotKey(HotKey hotKey) {
    // Use USB HID code for reliable serialization across debug/release modes.
    final usbHidCode = hotKey.key.usbHidUsage.toRadixString(16).padLeft(8, '0');
    return {'key': usbHidCode, 'modifiers': hotKey.modifiers?.map((m) => m.name).toList() ?? []};
  }

  static HotKey? deserializeHotKey(Map<String, dynamic> data) {
    try {
      final keyString = data['key'] as String;
      final modifierNames = (data['modifiers'] as List<dynamic>).cast<String>();
      final modifiers = modifierNames
          .map((name) => _modifierMap[name])
          .where((m) => m != null)
          .cast<HotKeyModifier>()
          .toList();
      // Try parsing as USB HID code first (new format), fall back to string parsing.
      final usbHidCode = int.tryParse(keyString, radix: 16);
      final key = usbHidCode != null ? PhysicalKeyboardKey(usbHidCode) : _findKeyByString(keyString);
      if (key != null) {
        return HotKey(key: key, modifiers: modifiers.isNotEmpty ? modifiers : null);
      }
    } catch (_) {
      // Ignore deserialization errors.
    }
    return null;
  }

  // Pattern-based key name matching (lowercase keys for case-insensitive matching).
  static const _keyNameMap = <String, PhysicalKeyboardKey>{
    'space': PhysicalKeyboardKey.space,
    'backspace': PhysicalKeyboardKey.backspace,
    'delete': PhysicalKeyboardKey.delete,
    'enter': PhysicalKeyboardKey.enter,
    'escape': PhysicalKeyboardKey.escape,
    'tab': PhysicalKeyboardKey.tab,
    'capslock': PhysicalKeyboardKey.capsLock,
    'arrowleft': PhysicalKeyboardKey.arrowLeft,
    'arrowup': PhysicalKeyboardKey.arrowUp,
    'arrowright': PhysicalKeyboardKey.arrowRight,
    'arrowdown': PhysicalKeyboardKey.arrowDown,
    'home': PhysicalKeyboardKey.home,
    'end': PhysicalKeyboardKey.end,
    'pageup': PhysicalKeyboardKey.pageUp,
    'pagedown': PhysicalKeyboardKey.pageDown,
    'equal': PhysicalKeyboardKey.equal,
    'minus': PhysicalKeyboardKey.minus,
  };

  static const _functionKeyMap = <String, PhysicalKeyboardKey>{
    'f1': PhysicalKeyboardKey.f1,
    'f2': PhysicalKeyboardKey.f2,
    'f3': PhysicalKeyboardKey.f3,
    'f4': PhysicalKeyboardKey.f4,
    'f5': PhysicalKeyboardKey.f5,
    'f6': PhysicalKeyboardKey.f6,
    'f7': PhysicalKeyboardKey.f7,
    'f8': PhysicalKeyboardKey.f8,
    'f9': PhysicalKeyboardKey.f9,
    'f10': PhysicalKeyboardKey.f10,
    'f11': PhysicalKeyboardKey.f11,
    'f12': PhysicalKeyboardKey.f12,
  };

  static const _digitKeyMap = <String, PhysicalKeyboardKey>{
    'digit0': PhysicalKeyboardKey.digit0,
    'digit1': PhysicalKeyboardKey.digit1,
    'digit2': PhysicalKeyboardKey.digit2,
    'digit3': PhysicalKeyboardKey.digit3,
    'digit4': PhysicalKeyboardKey.digit4,
    'digit5': PhysicalKeyboardKey.digit5,
    'digit6': PhysicalKeyboardKey.digit6,
    'digit7': PhysicalKeyboardKey.digit7,
    'digit8': PhysicalKeyboardKey.digit8,
    'digit9': PhysicalKeyboardKey.digit9,
  };

  static const _letterKeyMap = <String, PhysicalKeyboardKey>{
    'keya': PhysicalKeyboardKey.keyA,
    'keyb': PhysicalKeyboardKey.keyB,
    'keyc': PhysicalKeyboardKey.keyC,
    'keyd': PhysicalKeyboardKey.keyD,
    'keye': PhysicalKeyboardKey.keyE,
    'keyf': PhysicalKeyboardKey.keyF,
    'keyg': PhysicalKeyboardKey.keyG,
    'keyh': PhysicalKeyboardKey.keyH,
    'keyi': PhysicalKeyboardKey.keyI,
    'keyj': PhysicalKeyboardKey.keyJ,
    'keyk': PhysicalKeyboardKey.keyK,
    'keyl': PhysicalKeyboardKey.keyL,
    'keym': PhysicalKeyboardKey.keyM,
    'keyn': PhysicalKeyboardKey.keyN,
    'keyo': PhysicalKeyboardKey.keyO,
    'keyp': PhysicalKeyboardKey.keyP,
    'keyq': PhysicalKeyboardKey.keyQ,
    'keyr': PhysicalKeyboardKey.keyR,
    'keys': PhysicalKeyboardKey.keyS,
    'keyt': PhysicalKeyboardKey.keyT,
    'keyu': PhysicalKeyboardKey.keyU,
    'keyv': PhysicalKeyboardKey.keyV,
    'keyw': PhysicalKeyboardKey.keyW,
    'keyx': PhysicalKeyboardKey.keyX,
    'keyy': PhysicalKeyboardKey.keyY,
    'keyz': PhysicalKeyboardKey.keyZ,
  };

  static PhysicalKeyboardKey? _findKeyByString(String keyString) {
    final normalized = keyString.toLowerCase();

    // Try extracting USB HID code from toString() output:
    // PhysicalKeyboardKey#ec9ed(usbHidUsage: "0x0007002c", debugName: "Space")
    final usbHidMatch = RegExp(r'usbhidusage: "0x([0-9a-f]+)"').firstMatch(normalized);
    if (usbHidMatch != null) {
      final code = int.tryParse(usbHidMatch.group(1)!, radix: 16);
      if (code != null) return PhysicalKeyboardKey(code);
    }

    for (final entry in _keyNameMap.entries) {
      if (normalized.contains(entry.key)) return entry.value;
    }
    // Function keys before digits to avoid f1 matching f10.
    for (final entry in _functionKeyMap.entries) {
      if (normalized.contains(entry.key)) return entry.value;
    }
    for (final entry in _digitKeyMap.entries) {
      if (normalized.contains(entry.key)) return entry.value;
    }
    for (final entry in _letterKeyMap.entries) {
      if (normalized.contains(entry.key)) return entry.value;
    }

    return null;
  }

  /// Settings that "Reset All Settings" actually resets. Mirrors the original
  /// reset surface — notably excludes user-customized data (intro/credits regex
  /// patterns) and opt-in toggles prior versions didn't reset, so behavior
  /// stays identical for users.
  static List<String> _resettableKeys() => [
    enableDebugLogging.key,
    bufferSize.key,
    enableHardwareDecoding.key,
    enableHDR.key,
    preferredVideoCodec.key,
    preferredAudioCodec.key,
    viewMode.key,
    showHeroSection.key,
    seekTimeSmall.key,
    seekTimeLarge.key,
    sleepTimerDuration.key,
    audioSyncOffset.key,
    subtitleSyncOffset.key,
    volume.key,
    maxVolume.key,
    subtitleFontSize.key,
    subtitleTextColor.key,
    subtitleBorderSize.key,
    subtitleBorderColor.key,
    subtitleBackgroundColor.key,
    subtitleBackgroundOpacity.key,
    subtitlePosition.key,
    rememberTrackSelections.key,
    customDownloadPathType.key,
    downloadOnWifiOnly.key,
    autoCheckUpdatesOnStartup.key,
    showPerformanceOverlay.key,
    autoHidePerformanceOverlay.key,
    enableDiscordRPC.key,
    enableTraktScrobble.key,
    enableTraktWatchedSync.key,
    enableMalScrobble.key,
    enableAnilistScrobble.key,
    enableSimklScrobble.key,
    matchContentFrameRate.key,
    tunneledPlayback.key,
    defaultPlaybackSpeed.key,
    defaultBoxFitMode.key,
    autoPlayNextEpisode.key,
    useExoPlayer.key,
    alwaysKeepSidebarOpen.key,
    showUnwatchedCount.key,
    showEpisodeNumberOnCards.key,
    hideSpoilers.key,
    showNavBarLabels.key,
    globalShaderPreset.key,
    requireProfileSelectionOnOpen.key,
    useExternalPlayer.key,
    confirmExitOnBack.key,
    forceTvMode.key,
    ambientLighting.key,
    audioPassthrough.key,
    audioNormalization.key,
    themeMode.key,
    keyboardShortcuts.key,
    keyboardHotkeys.key,
    libraryDensity.key,
    _legacyUseSeasonPosterKey,
    episodePosterMode.key,
    mediaVersionPreferences.key,
    appLocale.key,
    customDownloadPath.key,
    videoPlayerNavigationEnabled.key,
    _legacyMpvConfigEntriesKey,
    mpvConfigText.key,
    mpvPresets.key,
    autoPip.key,
    customShaderPresets.key,
    selectedExternalPlayer.key,
    customExternalPlayers.key,
    _bufferSizeMigratedKey,
    customRelayUrl.key,
  ];

  Future<void> resetAllSettings() async {
    await Future.wait([
      ..._resettableKeys().map((k) => prefs.remove(k)),
      ...TrackerService.values.expand(
        (s) => [prefs.remove(trackerFilterModePref(s).key), prefs.remove(trackerFilterIdsPref(s).key)],
      ),
    ]);
  }

  Future<void> clearCache() async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    await PlexImageCacheManager.instance.emptyCache();
  }
}
