import 'dart:convert';
import '../media/ids.dart';
import '../media/playback_rate.dart';
import '../media/media_version_preference.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import '../models/hotkey_model.dart';
import 'image_cache_service.dart';
import 'package:plezy/utils/app_logger.dart';
import '../i18n/app_locale_utils.dart';
import '../i18n/strings.g.dart';
import '../models/mpv_config_models.dart';
import '../models/player_setting_scope.dart';
import '../models/external_player_models.dart';
import 'base_shared_preferences_service.dart';
import 'sensitive_prefs.dart';
import 'device_performance.dart';
import 'shortcut_action.dart';
export 'base_shared_preferences_service.dart'
    show
        Pref,
        BoolPref,
        IntPref,
        DoublePref,
        StringPref,
        NullableStringPref,
        StringListPref,
        EnumPref,
        NullableEnumPref,
        JsonPref;
import '../models/audio_quality_preset.dart';
import '../models/transcode_quality_preset.dart';
import '../models/home_section_config.dart';
import '../navigation/navigation_tabs.dart';
import '../utils/platform_detector.dart';
import 'trackers/tracker_constants.dart';
import '../profiles/profile.dart';
import '../watch_together/services/watch_together_relay_endpoint.dart';

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

/// Gap between cards in media grids (#2083, #1597). [tight] is the
/// pre-setting look, so nothing moves on update.
enum GridSpacing { tight, normal, spacious }

extension GridSpacingMetrics on GridSpacing {
  /// Inter-card gutter fed to the grid delegate's cross/main axis spacing.
  double get gridGap => switch (this) {
    GridSpacing.tight => 0,
    GridSpacing.normal => 6,
    GridSpacing.spacious => 12,
  };

  /// Vertical gap between the poster and the title inside a standard grid
  /// card. Only grid cells (Expanded poster) apply this; fixed-height hub-row
  /// cards keep the legacy 2px because their text band cannot absorb more.
  double get posterTitleGap => switch (this) {
    GridSpacing.tight => 2,
    GridSpacing.normal => 4,
    GridSpacing.spacious => 6,
  };
}

enum ViewMode { grid, list }

enum EpisodePosterMode { seriesPoster, seasonPoster, episodeThumbnail }

enum ContinueWatchingAction { play, details }

enum EpisodeAction { play, details }

/// How Specials (season 0) are placed in the episode watch order — the
/// sequence auto-advance, offline next/prev, and "download next N" walk.
enum SpecialsOrdering {
  /// Follow the backend's own ordering: Plex builds its server-side show
  /// queue from `/allLeaves` (aired order, Specials interleaved); Jellyfin's
  /// `/Shows/{id}/Episodes` order is preserved as returned (Specials placed
  /// only by explicit `AirsBefore*` metadata, per the server-wide
  /// `DisplaySpecialsWithinSeasons` setting). Client-side selections with no
  /// server order (offline queue, downloads, offline OnDeck) fall back to
  /// Specials-last.
  respectServer,

  /// Interleave Specials between regular episodes by air date on every
  /// surface (#1416), the way Plex's own play queue orders a show.
  airDate,

  /// Specials strictly after the regular seasons on every surface (#1952).
  specialsLast,
}

/// What the player does when playback enters an intro or credits marker.
/// One pref per marker kind (#2138).
enum SkipMarkerMode {
  /// Play through: no skip button, no countdown. The marker is invisible.
  off,

  /// Show the skip button; the viewer decides.
  button,

  /// Show the button and skip on its own after [SettingsService.autoSkipDelay].
  auto,
}

enum SubAssOverride { no, yes, scale, force, strip }

/// Resolution ASS/image subtitles are rasterized at.
///
/// iOS/tvOS (avfoundation VO) uses the [screen] vs [video] basis (video is much
/// cheaper on 4K displays; subs can't carry more detail than the video they're
/// typeset against). Android (libass overlay) instead downscales by a fixed
/// fraction of the surface — [screen] is full, and [threeQuarter]/[half]/[third]/
/// [quarter] trade sharpness for raster throughput on render-bound low-end TVs.
enum SubtitleRenderResolution { screen, video, threeQuarter, half, third, quarter }

/// Who reduces HDR content to what the display can actually show, on the Linux
/// native video plane.
///
/// [compositor] hands the compositor the source's own metadata and lets its tone
/// curve do the work — simple, and what Kodi does. [player] tone-maps in mpv to
/// the display's real peak and declares that peak instead, which is mpv's own
/// default and leaves the compositor an identity transform.
enum HdrToneMapping { compositor, player }

extension SubtitleRenderScale on SubtitleRenderResolution {
  /// Android libass overlay render scale (fraction of the surface resolution).
  /// Only Android reads this; the iOS-only [video] basis maps to full scale here.
  double get androidRenderScale => switch (this) {
    SubtitleRenderResolution.screen => 1.0,
    SubtitleRenderResolution.video => 1.0,
    SubtitleRenderResolution.threeQuarter => 0.75,
    SubtitleRenderResolution.half => 0.5,
    SubtitleRenderResolution.third => 1 / 3,
    SubtitleRenderResolution.quarter => 0.25,
  };
}

enum DvConversionModePreference { auto, disabled, dv81, hevcStrip }

extension DvConversionModePreferenceNativeValue on DvConversionModePreference {
  String get nativeValue => switch (this) {
    DvConversionModePreference.auto => 'auto',
    DvConversionModePreference.disabled => 'disabled',
    DvConversionModePreference.dv81 => 'dv81',
    DvConversionModePreference.hevcStrip => 'hevc_strip',
  };
}

enum PlaybackBufferTier { auto, large, extraLarge }

extension PlaybackBufferTierNativeValue on PlaybackBufferTier {
  String get nativeValue => switch (this) {
    PlaybackBufferTier.auto => 'auto',
    PlaybackBufferTier.large => 'large',
    PlaybackBufferTier.extraLarge => 'extra_large',
  };
}

const String _bufferSizeMigratedKey = 'buffer_size_migrated_to_auto';
const String _legacyBufferSizeKey = 'buffer_size';
const String _legacyDemuxerModeKey = 'demuxer_mode';
const String _legacyUseSeasonPosterKey = 'use_season_poster';
const String _legacyMpvConfigEntriesKey = 'mpv_config_entries';
const String _legacyUseExoPlayerKey = 'use_exoplayer';
const String _legacyAutoSkipIntroKey = 'auto_skip_intro';
const String _legacyAutoSkipCreditsKey = 'auto_skip_credits';

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

class AutomotiveUiScale {
  static const double min = 1.0;
  static const double max = 2.0;
  static const double defaultValue = 1.35;
}

/// Uses a larger default on car displays while honoring and clamping a stored
/// user adjustment on every platform.
class _AutomotiveUiScalePref extends Pref<double> {
  const _AutomotiveUiScalePref() : super('automotive_ui_scale');

  @override
  double readFrom(BaseSharedPreferencesService svc) {
    final fallback = PlatformDetector.isAutomotive() ? AutomotiveUiScale.defaultValue : 1.0;
    // Tolerant read, not `prefs.getDouble`: this is read while building the root
    // app, so a mistyped stored value would turn every launch into the error
    // widget instead of dropping the key (#1732).
    return svc.readDouble(key, defaultValue: fallback).clamp(AutomotiveUiScale.min, AutomotiveUiScale.max).toDouble();
  }

  @override
  Future<void> writeTo(BaseSharedPreferencesService svc, double value) =>
      svc.writeDouble(key, value.clamp(AutomotiveUiScale.min, AutomotiveUiScale.max).toDouble());
}

/// Migrates from the legacy `use_season_poster` boolean key.
class _EpisodePosterModePref extends EnumPref<EpisodePosterMode> {
  const _EpisodePosterModePref()
    : super('episode_poster_mode', values: EpisodePosterMode.values, defaultValue: EpisodePosterMode.episodeThumbnail);

  @override
  EpisodePosterMode readFrom(BaseSharedPreferencesService svc) {
    final legacyValue = svc.readNullableBool(_legacyUseSeasonPosterKey);
    if (legacyValue != null) {
      final migrated = legacyValue ? EpisodePosterMode.seasonPoster : EpisodePosterMode.seriesPoster;
      svc.prefs.remove(_legacyUseSeasonPosterKey);
      svc.prefs.setString(key, migrated.name);
      return migrated;
    }
    return super.readFrom(svc);
  }
}

/// Migrates from the legacy `auto_skip_*` booleans: on → [SkipMarkerMode.auto],
/// off → [SkipMarkerMode.button], which is what each used to mean.
class _SkipMarkerModePref extends EnumPref<SkipMarkerMode> {
  final String legacyKey;

  const _SkipMarkerModePref(super.key, {required this.legacyKey})
    : super(values: SkipMarkerMode.values, defaultValue: SkipMarkerMode.button);

  SkipMarkerMode fromLegacy(bool value) => value ? SkipMarkerMode.auto : SkipMarkerMode.button;

  @override
  SkipMarkerMode readFrom(BaseSharedPreferencesService svc) {
    // A committed mode is authoritative, including one restored before this
    // preference's first read. A leftover boolean must never replace it.
    if (svc.prefs.containsKey(key)) {
      if (svc.prefs.containsKey(legacyKey)) svc.prefs.remove(legacyKey);
      return super.readFrom(svc);
    }
    final legacyValue = svc.readNullableBool(legacyKey);
    if (legacyValue != null) {
      final migrated = fromLegacy(legacyValue);
      svc.prefs.setString(key, migrated.name);
      svc.prefs.remove(legacyKey);
      return migrated;
    }
    return super.readFrom(svc);
  }
}

/// Stored as the locale enum name; null/empty falls back to the device locale.
class _AppLocalePref extends Pref<AppLocale> {
  const _AppLocalePref() : super('app_locale');

  @override
  AppLocale readFrom(BaseSharedPreferencesService svc) {
    final code = svc.readNullableString(key);
    if (code == null || code.isEmpty) {
      return resolvePreferredAppLocale(PlatformDispatcher.instance.locales);
    }
    return AppLocale.values.asNameMap()[code] ?? AppLocale.en;
  }

  @override
  Future<void> writeTo(BaseSharedPreferencesService svc, AppLocale value) => svc.writeString(key, value.name);
}

/// Uses a macOS-disabled default and is forced off when [PlatformDetector] disables PiP.
class _AutoPipPref extends Pref<bool> {
  const _AutoPipPref() : super('auto_pip');

  @override
  bool readFrom(BaseSharedPreferencesService svc) {
    if (!PlatformDetector.supportsPictureInPicture()) return false;
    return svc.readNullableBool(key) ?? !Platform.isMacOS;
  }

  @override
  Future<void> writeTo(BaseSharedPreferencesService svc, bool value) => svc.writeBool(key, value);
}

class _UseExternalPlayerPref extends Pref<bool> {
  const _UseExternalPlayerPref() : super('use_external_player');

  @override
  bool readFrom(BaseSharedPreferencesService svc) {
    if (!PlatformDetector.supportsExternalPlayers()) return false;
    return svc.readNullableBool(key) ?? false;
  }

  @override
  Future<void> writeTo(BaseSharedPreferencesService svc, bool value) => svc.writeBool(key, value);
}

/// Native Dolby playback: bitstreaming on Android TV, Apple's EAC3+JOC
/// sample-buffer renderer on Apple TV. Both default on for the living-room
/// form factor, off everywhere else.
class _AudioPassthroughPref extends Pref<bool> {
  const _AudioPassthroughPref() : super('audio_passthrough');

  @override
  bool readFrom(BaseSharedPreferencesService svc) {
    final stored = svc.readNullableBool(key);
    if (stored != null) return stored;
    // TV form factors default to handing Dolby to the TV/AVR, preserving
    // surround. Android TV bitstreams Dolby/DTS; both Android backends decide
    // from the same source — the sink's advertised capabilities: Media3 via
    // AudioCapabilities, mpv via the route-probed audio-spdif list
    // (supportedMpvSpdifCodecs), which names only codecs the live route
    // accepts rather than forcing the whole set. That probe is the only
    // safety net on the mpv path: ao_audiotrack fails the open outright when a
    // route lied about a format, with no decode fallback behind it (#1458,
    // #1703). Apple TV routes E-AC-3 (incl. Atmos) through the native
    // sample-buffer renderer, hardware-verified on real receivers (#1300).
    return PlatformDetector.isAppleTV() || (Platform.isAndroid && PlatformDetector.isTV());
  }

  @override
  Future<void> writeTo(BaseSharedPreferencesService svc, bool value) => svc.writeBool(key, value);
}

String? _trimEmptyAsNull(String? v) {
  final t = v?.trim();
  return (t == null || t.isEmpty) ? null : t;
}

String? _normalizeRelayBaseUrl(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final endpoint = WatchTogetherRelayEndpoint.tryParseCustom(value);
  if (endpoint == null) {
    throw FormatException('Invalid Watch Together relay base URL');
  }
  return endpoint.canonicalBaseUrl;
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
    final text = svc.readNullableString(key);
    if (text != null) return text;

    final legacyJson = svc.readNullableString(_legacyMpvConfigEntriesKey);
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

Map<String, HotKey> _defaultKeyboardHotkeys() => {
  for (final action in ShortcutAction.values) action.id: action.defaultHotKey,
};

Map<String, HotKey?> _decodeKeyboardHotkeys(dynamic raw) {
  final result = <String, HotKey?>{};
  for (final entry in (raw as Map<String, dynamic>).entries) {
    final value = entry.value;
    if (value is! Map<String, dynamic>) continue;
    if (value['disabled'] == true) {
      result[entry.key] = null;
      continue;
    }
    final hotkey = SettingsService.deserializeHotKey(value);
    if (hotkey != null) result[entry.key] = hotkey;
  }
  return <String, HotKey?>{..._defaultKeyboardHotkeys(), ...result};
}

/// Shared fan-out for a group of preferences. The first observer installs one
/// listener on each preference; additional builders subscribe only to this
/// notifier. Upstream listeners are removed when the last observer leaves, so
/// short-lived non-const preference lists retain the old mount/unmount behavior.
class _PreferenceGroupListenable extends ChangeNotifier {
  final List<Listenable> _children;
  late final VoidCallback _relay = notifyListeners;

  _PreferenceGroupListenable(this._children);

  @override
  void addListener(VoidCallback listener) {
    final shouldAttach = !hasListeners;
    super.addListener(listener);
    if (!shouldAttach) return;
    for (final child in _children) {
      child.addListener(_relay);
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    final wasAttached = hasListeners;
    super.removeListener(listener);
    if (!wasAttached || hasListeners) return;
    for (final child in _children) {
      child.removeListener(_relay);
    }
  }
}

class SettingsService extends BaseSharedPreferencesService {
  static const String defaultIntroPattern = r'(?:^|\b)(?:intro(?:duction)?|opening)(?:\b|$)|^op(?:\s?\d+)?$';
  static const String defaultCreditsPattern = r'(?:^|\b)(?:outro|closing|credits?|ending)(?:\b|$)|^ed(?:\s?\d+)?$';

  static const enableDebugLogging = BoolPref('enable_debug_logging', onWrite: setLoggerLevel);
  static const crashReporting = BoolPref('crash_reporting', defaultValue: true);
  static const enableHardwareDecoding = BoolPref('enable_hardware_decoding', defaultValue: true);
  static const enableHDR = BoolPref('enable_hdr', defaultValue: true);
  // Linux native video plane only. Defaults to the compositor: photographed on a
  // 400-nit HDR output against a PQ chart, the compositor keeps 400 -> 1000 nits
  // monotonic and separated while the player leg flattens it. The player path
  // drives mpv's legacy vo_gpu, whose own standalone output scores the same, so
  // the gap is the renderer rather than the wiring. Compositor also needs no
  // knowledge of the display.
  static const hdrToneMapping = EnumPref<HdrToneMapping>(
    'hdr_tone_mapping',
    values: HdrToneMapping.values,
    defaultValue: HdrToneMapping.compositor,
  );
  static const viewMode = EnumPref<ViewMode>('view_mode', values: ViewMode.values, defaultValue: ViewMode.grid);
  static const seekTimeSmall = IntPref('seek_time_small', defaultValue: 10);
  static const seekTimeLarge = IntPref('seek_time_large', defaultValue: 30);
  static const rewindOnResume = IntPref('rewind_on_resume');
  static const showHeroSection = BoolPref('show_hero_section', defaultValue: true);
  static const tvFullCardLayout = BoolPref('tv_full_card_layout', defaultValue: false);
  static const focusGlow = BoolPref('focus_glow', defaultValue: true);
  static const useGlobalHubs = BoolPref('use_global_hubs', defaultValue: true);
  static const showServerNameOnHubs = BoolPref('show_server_name_on_hubs');
  static const groupLibrariesByServer = BoolPref('group_libraries_by_server', defaultValue: true);
  static const sleepTimerDuration = IntPref('sleep_timer_duration', defaultValue: 30);
  static const audioSyncOffset = IntPref('audio_sync_offset');
  static const subtitleSyncOffset = IntPref('subtitle_sync_offset');
  static const subtitleSearchLanguage = NullableStringPref('subtitle_search_language');
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
  static const subtitleRenderResolution = EnumPref<SubtitleRenderResolution>(
    'subtitle_render_resolution',
    values: SubtitleRenderResolution.values,
    defaultValue: SubtitleRenderResolution.screen,
  );
  static const subtitleBold = BoolPref('subtitle_bold');
  static const subtitleItalic = BoolPref('subtitle_italic');

  /// Render text subtitles (SRT/VTT/mov_text) anchored to the physical screen
  /// instead of the video rect, so they land in the letterbox bars of
  /// widescreen video (#1730). ExoPlayer backend only; mpv already places
  /// plaintext subtitles in the margins by default (sub-use-margins=yes).
  static const subtitleAnchorToScreen = BoolPref('subtitle_anchor_to_screen');
  static const cleanedOldImageCache = BoolPref('cleaned_old_image_cache');
  static const rememberTrackSelections = BoolPref('remember_track_selections', defaultValue: true);

  /// Episode advance follows the server's per-episode audio/subtitle
  /// selections instead of carrying the current choice over (#1717).
  static const followServerTrackSelections = BoolPref('follow_server_track_selections');
  static const showChapterMarkersOnTimeline = BoolPref('show_chapter_markers_on_timeline', defaultValue: true);
  static const clickVideoTogglesPlayback = BoolPref('click_video_toggles_playback');
  static const skipIntroMode = _SkipMarkerModePref('skip_intro_mode', legacyKey: _legacyAutoSkipIntroKey);
  static const skipCreditsMode = _SkipMarkerModePref('skip_credits_mode', legacyKey: _legacyAutoSkipCreditsKey);

  /// Previous format-v1 representations of these logical preferences.
  /// Shared by the typed migration and portable settings codec.
  static const legacySkipMarkerPrefs = {
    _legacyAutoSkipIntroKey: skipIntroMode,
    _legacyAutoSkipCreditsKey: skipCreditsMode,
  };

  static const forceSkipMarkerFallback = BoolPref('force_skip_marker_fallback');
  static const autoSkipDelay = IntPref('auto_skip_delay', defaultValue: 5);
  static const introPattern = StringPref('intro_pattern', defaultValue: defaultIntroPattern);
  static const creditsPattern = StringPref('credits_pattern', defaultValue: defaultCreditsPattern);
  static const customDownloadPathType = NullableStringPref('custom_download_path_type');
  static const downloadOnWifiOnly = BoolPref('download_on_wifi_only');
  static const autoRemoveWatchedDownloads = BoolPref('auto_remove_watched_downloads');

  /// Set once the user has seen the pre-flight "background downloads are
  /// blocked" dialog. The persistent Downloads-screen banner covers repeat
  /// offenders, so the interrupting dialog is shown exactly once.
  static const backgroundDownloadWarningAcknowledged = BoolPref('background_download_warning_ack');

  /// Remembered state of the "Include Specials" toggle on the show download
  /// dialog. Defaults to true (include) so existing behavior is unchanged;
  /// turning it off persists so the next download keeps the choice.
  static const downloadIncludeSpecials = BoolPref('download_include_specials', defaultValue: true);
  static const autoCheckUpdatesOnStartup = BoolPref('auto_check_updates_on_startup', defaultValue: true);
  static const showPerformanceOverlay = BoolPref('show_performance_overlay');
  static const autoHidePerformanceOverlay = BoolPref('auto_hide_performance_overlay', defaultValue: true);
  static const enableDiscordRPC = BoolPref('enable_discord_rpc');
  static const enableTraktWatchedSync = BoolPref('enable_trakt_watched_sync', defaultValue: true);
  static const matchContentFrameRate = BoolPref('match_content_frame_rate');
  static const matchContentResolution = BoolPref('match_content_resolution');
  static const tunneledPlayback = BoolPref('tunneled_playback', defaultValue: false);
  static const dvConversionMode = EnumPref<DvConversionModePreference>(
    'dv_conversion_mode',
    values: DvConversionModePreference.values,
    defaultValue: DvConversionModePreference.auto,
  );
  static const defaultQualityPreset = EnumPref<TranscodeQualityPreset>(
    'default_quality_preset',
    values: TranscodeQualityPreset.values,
    defaultValue: TranscodeQualityPreset.original,
  );

  /// Startup quality cap applied instead of [defaultQualityPreset] when the
  /// device is on a cellular-only connection. Null = follow
  /// [defaultQualityPreset].
  static const cellularQualityPreset = NullableEnumPref<TranscodeQualityPreset>(
    'cellular_quality_preset',
    values: TranscodeQualityPreset.values,
  );

  /// Serve a source that already fits under the selected quality preset by
  /// direct playing the file instead of transcoding it (#2152). Off restores
  /// the pre-#2152 behavior — any non-original preset always transcodes — for
  /// users who deliberately request a server encode to sidestep a decoder
  /// limitation (#2193). Plex-only by design: MediaBrowser servers make the
  /// equivalent direct-play-vs-transcode call server-side.
  static const directPlayCoveredQuality = BoolPref('direct_play_covered_quality', defaultValue: true);
  static const musicQualityPreset = EnumPref<AudioQualityPreset>(
    'music_quality_preset',
    values: AudioQualityPreset.values,
    defaultValue: AudioQualityPreset.original,
  );

  /// Music player volume (0–100), independent of the video player's
  /// [volume] so desktop music listening levels don't drag video loudness
  /// around.
  static const musicVolume = DoublePref('music_volume', defaultValue: 100.0);

  /// Restore the last music session parked-paused on launch (#2148).
  static const resumeMusicOnLaunch = BoolPref('resume_music_on_launch', defaultValue: true);
  static const autoPlayNextEpisode = BoolPref('auto_play_next_episode', defaultValue: true);

  /// Seconds the Play Next prompt counts down before auto-advancing (#1827).
  /// 0 skips the prompt entirely and starts the next episode immediately.
  /// Only consulted while [autoPlayNextEpisode] is on.
  static final playNextCountdown = IntPref('play_next_countdown', defaultValue: 5, transform: (v) => v.clamp(0, 30));

  /// Touch gestures on the player surface (#1810). Each defaults on; the
  /// edge swipes gate [MobileEdgeAdjustmentTracker] tracking and the zoom
  /// pref gates the pinch recognizer in the player screen.
  static const gestureBrightnessSwipe = BoolPref('gesture_brightness_swipe', defaultValue: true);
  static const gestureVolumeSwipe = BoolPref('gesture_volume_swipe', defaultValue: true);
  static const gesturePinchToZoom = BoolPref('gesture_pinch_to_zoom', defaultValue: true);

  /// Remember the brightness level set by the swipe gesture (#2178). When on,
  /// playback starts at [rememberedBrightnessLevel] instead of the system
  /// level; the player exit still restores the pre-playback brightness.
  static const rememberBrightnessLevel = BoolPref('remember_brightness_level');

  /// Last brightness the swipe gesture settled on while
  /// [rememberBrightnessLevel] was enabled. Negative means "never set";
  /// device-local runtime state, so reset-only in the registry.
  static const rememberedBrightnessLevel = DoublePref('remembered_brightness_level', defaultValue: -1.0);

  /// Deinterlace interlaced video via mpv's `deinterlace=auto` (#2149).
  /// mpv-only by design: ExoPlayer has no filter chain.
  static const deinterlace = BoolPref('deinterlace');

  /// Remembered state of the player's always-on-top toggle (#931). The window
  /// flag itself is only held while a player is open; this pref re-applies it
  /// on the next playback (including autoplay episode transitions).
  static const playerAlwaysOnTop = BoolPref('player_always_on_top');

  /// Where Specials (season 0) land in the episode watch order (#1416/#1952).
  /// Consumed by [sortEpisodesByWatchOrder] (Jellyfin online queue, offline
  /// next/prev, download/sync "next N", offline OnDeck, Plex fallback queue)
  /// and by the Plex show play-queue source URI.
  static const specialsOrdering = EnumPref<SpecialsOrdering>(
    'specials_ordering',
    values: SpecialsOrdering.values,
    defaultValue: SpecialsOrdering.respectServer,
  );

  /// mpv is the Android backend; ExoPlayer stays selectable as the escape
  /// hatch while it still ships.
  ///
  /// Deliberately a different key from the `use_exoplayer` it replaces. That
  /// key only ever holds an explicit pick made while ExoPlayer was the
  /// default, and honoring those picks would leave the devices that most
  /// need the new backend on the old one. Dropping it ([onInit]) puts every
  /// install on mpv; choosing ExoPlayer again writes this key and sticks.
  static const useExoPlayer = BoolPref('android_use_exoplayer');
  static const startupSection = EnumPref<NavigationTabId>(
    'startup_section',
    values: NavigationTabId.values,
    defaultValue: NavigationTabId.discover,
  );

  /// Whether the Explore tab (Plex Discover / tracker catalog rows) is shown
  /// at all. UI-only: catalog sources stay connected so watchlist surfaces
  /// keep working while the tab is hidden.
  static const showExploreTab = BoolPref('show_explore_tab', defaultValue: true);
  static const alwaysKeepSidebarOpen = BoolPref('always_keep_sidebar_open');

  /// Sidebar Libraries section expansion. Persisted so a collapsed section
  /// stays collapsed across launches instead of springing back open (#1896).
  static const librariesSectionExpanded = BoolPref('libraries_section_expanded', defaultValue: true);
  static const showUnwatchedCount = BoolPref('show_unwatched_count', defaultValue: true);

  /// The corner checkmark on watched posters/thumbnails (#1998). Progress bars
  /// and unwatched counts are unaffected.
  static const showWatchedIndicators = BoolPref('show_watched_indicators', defaultValue: true);
  static const showEpisodeNumberOnCards = BoolPref('show_episode_number_on_cards', defaultValue: true);
  static const showSeasonPostersOnTabs = BoolPref('show_season_posters_on_tabs');
  static const hideSpoilers = BoolPref('hide_spoilers');
  static const showNavBarLabels = BoolPref('show_nav_bar_labels', defaultValue: true);
  static const globalShaderPreset = StringPref('global_shader_preset', defaultValue: 'none');
  static const requireProfileSelectionOnOpen = BoolPref('require_profile_selection_on_open');
  static const useExternalPlayer = _UseExternalPlayerPref();
  static const forceTvMode = BoolPref('force_tv_mode');
  static const visualEffects = EnumPref<VisualEffectsSetting>(
    'visual_effects',
    values: VisualEffectsSetting.values,
    defaultValue: VisualEffectsSetting.auto,
  );
  static const ambientLighting = BoolPref('ambient_lighting');
  static const audioPassthrough = _AudioPassthroughPref();
  static const audioNormalization = BoolPref('audio_normalization');
  static const audioDownmix = BoolPref('audio_downmix');
  static const audioDownmixNormalize = BoolPref('audio_downmix_normalize', defaultValue: true);
  static const liveTvDefaultFavorites = BoolPref('live_tv_default_favorites');
  static const matchRefreshRate = BoolPref('match_refresh_rate');
  static const matchDynamicRange = BoolPref('match_dynamic_range');
  static const appLocale = _AppLocalePref();
  static const autoPip = _AutoPipPref();
  static const customDownloadPath = NullableStringPref('custom_download_path');
  static final customRelayUrl = NullableStringPref('custom_relay_url', transform: _normalizeRelayBaseUrl);

  static NullableStringPref recentRoomsForProfile(String profileId) {
    if (profileId.trim().isEmpty) {
      throw ArgumentError.value(profileId, 'profileId', 'Must not be empty');
    }
    return NullableStringPref(profileScopedPrefsKey(profileId, 'watch_together_recent_rooms'));
  }

  static final companionRemoteLastHostAddress = NullableStringPref(
    'companion_remote_last_host_address',
    transform: _trimEmptyAsNull,
  );

  static final maxVolume = IntPref('max_volume', defaultValue: 100, transform: (v) => v.clamp(100, 300));
  static final downmixCenterBoost = IntPref('downmix_center_boost', transform: (v) => v.clamp(0, 12));
  static final subtitlePosition = IntPref('subtitle_position', defaultValue: 100, transform: (v) => v.clamp(0, 100));
  static final defaultPlaybackSpeed = DoublePref(
    'default_playback_speed',
    defaultValue: 1.0,
    transform: (v) => v.clamp(minimumPlaybackRate, maximumPlaybackRate),
  );
  static final defaultBoxFitMode = IntPref('default_box_fit_mode', transform: (v) => v.clamp(0, 2));

  // Where a change made in the player's settings sheet persists (see
  // [PlayerSettingScope]). Defaults preserve the pre-existing behavior:
  // every change updates the global default.
  static const playbackSpeedScope = EnumPref<PlayerSettingScope>(
    'playback_speed_scope',
    values: PlayerSettingScope.values,
    defaultValue: PlayerSettingScope.global,
  );
  static const shaderPresetScope = EnumPref<PlayerSettingScope>(
    'shader_preset_scope',
    values: PlayerSettingScope.values,
    defaultValue: PlayerSettingScope.global,
  );
  static const boxFitScope = EnumPref<PlayerSettingScope>(
    'box_fit_scope',
    values: PlayerSettingScope.values,
    defaultValue: PlayerSettingScope.global,
  );

  /// One scope for both sync offsets: they are tuned together and a user who
  /// wants per-title subtitle offsets wants per-title audio offsets too.
  static const syncOffsetScope = EnumPref<PlayerSettingScope>(
    'sync_offset_scope',
    values: PlayerSettingScope.values,
    defaultValue: PlayerSettingScope.global,
  );
  static final displaySwitchDelay = IntPref('display_switch_delay', transform: (v) => v.clamp(0, 10));

  static ThemeMode _tvAwareThemeModeDefault() => PlatformDetector.isTV() ? ThemeMode.oled : ThemeMode.system;
  static const themeMode = EnumPref<ThemeMode>(
    'theme_mode',
    values: ThemeMode.values,
    defaultValueProvider: _tvAwareThemeModeDefault,
  );
  static const videoPlayerNavigationEnabled = BoolPref(
    'video_player_navigation_enabled',
    defaultValueProvider: PlatformDetector.isTV,
  );
  static const enableCompanionRemoteServer = BoolPref(
    'enable_companion_remote_server',
    defaultValueProvider: PlatformDetector.isDesktopOS,
  );
  static const startInFullscreen = BoolPref('start_in_fullscreen');
  static const exitFullscreenOnPlayerClose = BoolPref('exit_fullscreen_on_player_close');

  static const playbackBufferTier = EnumPref<PlaybackBufferTier>(
    'playback_buffer_tier',
    values: PlaybackBufferTier.values,
    defaultValue: PlaybackBufferTier.auto,
  );
  static const libraryDensity = _LibraryDensityPref();
  static const gridSpacing = EnumPref<GridSpacing>(
    'grid_spacing',
    values: GridSpacing.values,
    defaultValue: GridSpacing.tight,
  );
  static const automotiveUiScale = _AutomotiveUiScalePref();
  static const tvCornerSpotlightBackdrop = BoolPref('tv_corner_spotlight_backdrop');
  static const episodePosterMode = _EpisodePosterModePref();
  static const continueWatchingAction = EnumPref<ContinueWatchingAction>(
    'continue_watching_action',
    values: ContinueWatchingAction.values,
    defaultValue: ContinueWatchingAction.play,
  );
  static const episodeAction = EnumPref<EpisodeAction>(
    'episode_action',
    values: EpisodeAction.values,
    defaultValue: EpisodeAction.play,
  );
  static const mpvConfigText = _MpvConfigTextPref();

  /// Configurable Home rows that merge selected libraries into one row
  /// instead of one row per library (#1652).
  static final homeSections = JsonPref<List<HomeSectionConfig>>(
    'home_sections',
    defaultValue: const [],
    encode: (v) => json.encode(v.map((section) => section.toJson()).toList()),
    decode: (raw) => (raw as List).map((e) => HomeSectionConfig.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
  );

  /// Saved display order for Home rows (both configured sections and
  /// Plex-promoted managed hubs) — see `home_layout_settings_screen.dart`.
  static final homeRowOrder = JsonPref<List<String>>(
    'home_row_order',
    defaultValue: const [],
    encode: (v) => json.encode(v),
    decode: (raw) => (raw as List).whereType<String>().toList(),
  );

  static final keyboardHotkeys = JsonPref<Map<String, HotKey?>>(
    'keyboard_hotkeys',
    defaultValue: <String, HotKey?>{..._defaultKeyboardHotkeys()},
    encode: (values) => json.encode(
      values.map((key, hotkey) => MapEntry(key, hotkey == null ? const {'disabled': true} : serializeHotKey(hotkey))),
    ),
    decode: _decodeKeyboardHotkeys,
  );
  static final mediaVersionPreferences = JsonPref<Map<String, MediaVersionPreference>>(
    'media_version_preferences',
    defaultValue: const {},
    encode: (v) => json.encode(v.map((k, pref) => MapEntry(k, pref.toJson()))),
    // Legacy values were bare ints; MediaVersionPreference.fromJson accepts both.
    decode: (raw) => (raw as Map<String, dynamic>).map((k, v) => MapEntry(k, MediaVersionPreference.fromJson(v))),
  );

  /// Library-/title-scoped values for the player-sheet settings, managed by
  /// [ScopedPlayerPrefs]: property id → scope key → `{'v': value, 't': ms}`.
  static final scopedPlayerPrefValues = JsonPref<Map<String, dynamic>>(
    'scoped_player_pref_values',
    defaultValue: const {},
    encode: json.encode,
    decode: (raw) => Map<String, dynamic>.from(raw as Map),
  );

  /// Local record of when items were last played on this device
  /// (item/show globalKey → epoch ms). Written by LocalPlaybackHistory; used
  /// to pick the last-played sibling in the Continue Watching dedup (#1492).
  static final localLastPlayedAt = JsonPref<Map<String, int>>(
    'local_last_played_at',
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

  static IntPref watchedThresholdPref(ServerId serverId) => IntPref('watched_threshold_$serverId', defaultValue: 90);

  /// Library section the user last picked as a DVR recording target, keyed by
  /// subscription type (movie/show) so the two don't clobber each other.
  /// 0 = unset (only explicit picks are written; the server template default
  /// keeps applying until the user chooses).
  static IntPref dvrTargetSectionPref(ServerId serverId, int type) => IntPref('dvr_target_section_${type}_$serverId');

  /// Per-service "scrobble to this tracker" toggle. Trakt's second toggle
  /// ([enableTraktWatchedSync]) has no counterpart on the other services and
  /// stays a standalone constant.
  static BoolPref scrobblePref(TrackerService s) => BoolPref('enable_${s.name}_scrobble', defaultValue: true);

  static EnumPref<TrackerLibraryFilterMode> trackerFilterModePref(TrackerService s) => EnumPref(
    'tracker_library_filter_mode_${s.name}',
    values: TrackerLibraryFilterMode.values,
    defaultValue: TrackerLibraryFilterMode.blacklist,
  );

  static StringListPref trackerFilterIdsPref(TrackerService s) =>
      StringListPref('tracker_library_filter_ids_${s.name}');

  /// Identity-keyed preference groups. Const list literals are canonicalized,
  /// so every builder at a call site shares one fan-out for the process
  /// lifetime. Dynamic lists receive weak entries: they get the same behavior
  /// as `Listenable.merge` without accumulating in a process-lifetime map.
  final Expando<_PreferenceGroupListenable> _preferenceGroupListenables = Expando<_PreferenceGroupListenable>(
    'settings preference groups',
  );

  Listenable listenableOfAll(List<Pref<Object?>> prefs) {
    return _preferenceGroupListenables[prefs] ??= _PreferenceGroupListenable(
      prefs.map(listenableOf).toList(growable: false),
    );
  }

  SettingsService._();

  static SettingsService? _cachedInstance;

  static Future<SettingsService> getInstance() async {
    _cachedInstance ??= await BaseSharedPreferencesService.initializeInstance(() => SettingsService._());
    return _cachedInstance!;
  }

  /// Synchronous access to the singleton, or null if not yet initialized.
  static SettingsService? get instanceOrNull => _cachedInstance;

  /// Synchronous access to the bootstrapped singleton.
  static SettingsService get instance {
    final instance = _cachedInstance;
    if (instance == null) {
      throw StateError('SettingsService has not been initialized. Call SettingsService.getInstance() first.');
    }
    return instance;
  }

  /// Drop the cached singleton so the next [getInstance] call rebuilds against
  /// the current SharedPreferences state. Test-only — pair with
  /// [BaseSharedPreferencesService.resetForTesting].
  @visibleForTesting
  static void resetForTesting() {
    _cachedInstance = null;
  }

  @override
  Future<void> onInit() async {
    _assertCredentialsReadable();

    const legacyRecentRoomsKey = 'watch_together_recent_rooms';
    await prefs.remove(legacyRecentRoomsKey);
    // One-way move to the mpv default: the pre-`android_use_exoplayer` pick is
    // dropped rather than carried over, and nothing reads the old key.
    await prefs.remove(_legacyUseExoPlayerKey);

    final storedRelay = readNullableString(customRelayUrl.key);
    if (storedRelay == null) return;
    final endpoint = WatchTogetherRelayEndpoint.tryParseCustom(storedRelay);
    if (endpoint == null) {
      await prefs.remove(customRelayUrl.key);
    } else if (endpoint.canonicalBaseUrl != storedRelay) {
      await prefs.setString(customRelayUrl.key, endpoint.canonicalBaseUrl);
    }
  }

  /// Raises [UnreadableSensitivePreferenceException] if any stored credential
  /// has a type we cannot read.
  ///
  /// The credential stores themselves — `CredentialVault`, `TrackerAccountStore`,
  /// `SeerrSessionStore` — are consulted long after startup, where a throw
  /// would surface as an unhandled provider error rather than the repair
  /// prompt. Checking here puts the failure inside a fatal gate step, while
  /// the store is open and a surgical single-key repair is still possible
  /// (#1732).
  ///
  /// One pass over the already-cached key set; no I/O.
  void _assertCredentialsReadable() {
    for (final key in prefs.keys) {
      if (isSensitivePrefKey(key)) readTolerantString(prefs, key);
    }
  }

  static Map<String, HotKey> defaultKeyboardHotkeys() => _defaultKeyboardHotkeys();

  /// Unknown libraries are allowed only when no filter is configured.
  bool isLibraryAllowedForTracker(TrackerService service, String? libraryGlobalKey) {
    final filterIds = read(trackerFilterIdsPref(service));
    final mode = read(trackerFilterModePref(service));
    if (libraryGlobalKey == null) {
      return mode == TrackerLibraryFilterMode.blacklist && filterIds.isEmpty;
    }
    final inList = filterIds.contains(libraryGlobalKey);
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
  ///
  /// Like mpv's own config-file parser, one pair of matching quotes around the
  /// whole value is stripped (`sub-font = 'Netflix Sans'`). These values are
  /// applied through the property API, which takes strings verbatim, so an
  /// unstripped quote silently selects a nonexistent font family or fails a
  /// numeric parse (#2025).
  static Map<String, String> parseMpvConfigText(String text) {
    final result = <String, String>{};
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final eqIndex = trimmed.indexOf('=');
      if (eqIndex <= 0) continue;
      final k = trimmed.substring(0, eqIndex).trim();
      var v = trimmed.substring(eqIndex + 1).trim();
      if (v.length >= 2 && (v[0] == "'" || v[0] == '"') && v[v.length - 1] == v[0]) {
        v = v.substring(1, v.length - 1);
      }
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

  /// Preference registry behind "Reset All Settings" and settings export.
  /// Every participating preference is named exactly once, in the group that
  /// states its policy; anything absent from all three groups takes part in
  /// neither surface (credentials, runtime state, migration sentinels).
  ///
  /// Group one: reset *and* exported — the ordinary case.
  static final List<Pref<Object?>> _resetAndPortablePrefs = [
    enableDebugLogging,
    enableHardwareDecoding,
    enableHDR,
    hdrToneMapping,
    viewMode,
    seekTimeSmall,
    seekTimeLarge,
    showHeroSection,
    sleepTimerDuration,
    audioSyncOffset,
    subtitleSyncOffset,
    subtitleSearchLanguage,
    volume,
    subtitleFontSize,
    subtitleTextColor,
    subtitleBorderSize,
    subtitleBorderColor,
    subtitleBackgroundColor,
    subtitleBackgroundOpacity,
    rememberTrackSelections,
    followServerTrackSelections,
    downloadOnWifiOnly,
    backgroundDownloadWarningAcknowledged,
    downloadIncludeSpecials,
    autoCheckUpdatesOnStartup,
    showPerformanceOverlay,
    autoHidePerformanceOverlay,
    enableDiscordRPC,
    enableTraktWatchedSync,
    // Scrobble toggle, one per tracker service.
    for (final s in TrackerService.values) scrobblePref(s),
    matchContentFrameRate,
    matchContentResolution,
    tunneledPlayback,
    dvConversionMode,
    musicVolume,
    resumeMusicOnLaunch,
    autoPlayNextEpisode,
    playNextCountdown,
    gestureBrightnessSwipe,
    gestureVolumeSwipe,
    gesturePinchToZoom,
    rememberBrightnessLevel,
    directPlayCoveredQuality,
    deinterlace,
    playerAlwaysOnTop,
    specialsOrdering,
    useExoPlayer,
    startupSection,
    showExploreTab,
    alwaysKeepSidebarOpen,
    librariesSectionExpanded,
    showUnwatchedCount,
    showWatchedIndicators,
    showEpisodeNumberOnCards,
    showSeasonPostersOnTabs,
    hideSpoilers,
    showNavBarLabels,
    globalShaderPreset,
    requireProfileSelectionOnOpen,
    useExternalPlayer,
    forceTvMode,
    visualEffects,
    ambientLighting,
    audioPassthrough,
    audioNormalization,
    audioDownmix,
    audioDownmixNormalize,
    appLocale,
    autoPip,
    maxVolume,
    downmixCenterBoost,
    subtitlePosition,
    subtitleAnchorToScreen,
    defaultPlaybackSpeed,
    defaultBoxFitMode,
    playbackSpeedScope,
    shaderPresetScope,
    boxFitScope,
    syncOffsetScope,
    scopedPlayerPrefValues,
    themeMode,
    videoPlayerNavigationEnabled,
    playbackBufferTier,
    libraryDensity,
    gridSpacing,
    automotiveUiScale,
    tvCornerSpotlightBackdrop,
    episodePosterMode,
    continueWatchingAction,
    episodeAction,
    homeSections,
    keyboardHotkeys,
    // Library filters, one pair per tracker service.
    for (final s in TrackerService.values) ...[trackerFilterModePref(s), trackerFilterIdsPref(s)],
  ];

  /// Group two: exported but *not* reset. Mirrors the original reset surface —
  /// user-customized data (intro/credits regex patterns) and opt-in toggles
  /// prior versions didn't reset, so behavior stays identical for users.
  static final List<Pref<Object?>> _portableOnlyPrefs = [
    rewindOnResume,
    tvFullCardLayout,
    focusGlow,
    useGlobalHubs,
    showServerNameOnHubs,
    groupLibrariesByServer,
    rotationLocked,
    subAssOverride,
    subtitleRenderResolution,
    subtitleBold,
    subtitleItalic,
    showChapterMarkersOnTimeline,
    clickVideoTogglesPlayback,
    skipIntroMode,
    skipCreditsMode,
    forceSkipMarkerFallback,
    autoSkipDelay,
    introPattern,
    creditsPattern,
    autoRemoveWatchedDownloads,
    defaultQualityPreset,
    cellularQualityPreset,
    musicQualityPreset,
    liveTvDefaultFavorites,
    matchRefreshRate,
    matchDynamicRange,
    displaySwitchDelay,
    enableCompanionRemoteServer,
    startInFullscreen,
    exitFullscreenOnPlayerClose,
  ];

  /// Group three: reset but *not* exported — device-local paths, endpoints and
  /// per-device state plus user-authored player configuration, none of which
  /// should travel between installations.
  static final List<Pref<Object?>> _resetOnlyPrefs = [
    customDownloadPathType,
    mediaVersionPreferences,
    localLastPlayedAt,
    customDownloadPath,
    mpvConfigText,
    mpvPresets,
    customShaderPresets,
    selectedExternalPlayer,
    customExternalPlayers,
    customRelayUrl,
    companionRemoteLastHostAddress,
    rememberedBrightnessLevel,
  ];

  /// Settings that "Reset All Settings" actually resets.
  static List<Pref<Object?>> get _resettablePrefs => [..._resetAndPortablePrefs, ..._resetOnlyPrefs];

  /// Settings carried by settings export/import files.
  static List<Pref<Object?>> get portablePrefs => [..._resetAndPortablePrefs, ..._portableOnlyPrefs];

  Future<void> resetAllSettings() async {
    // Marker modes are portable-only. Preserve cold-upgrade choices before
    // retiring their old representation, just as if they had already been read.
    for (final entry in legacySkipMarkerPrefs.entries) {
      final pref = entry.value;
      if (!prefs.containsKey(pref.key)) {
        final legacyValue = readNullableBool(entry.key);
        if (legacyValue != null) await pref.writeTo(this, pref.fromLegacy(legacyValue));
      }
      await prefs.remove(entry.key);
    }
    await Future.wait([
      ..._resettablePrefs.map((p) => prefs.remove(p.key)),
      // Legacy migration sentinels — removed alongside the keys they guarded.
      prefs.remove(_legacyUseSeasonPosterKey),
      prefs.remove(_legacyMpvConfigEntriesKey),
      prefs.remove(_legacyBufferSizeKey),
      prefs.remove(_legacyDemuxerModeKey),
      prefs.remove(_bufferSizeMigratedKey),
    ]);
    refreshListenables();
  }

  /// Push current stored values into every active listenable. Use after bulk
  /// operations that bypass [write] (e.g. import-from-file rewrites the
  /// underlying SharedPreferences directly).
  void refreshListenables() {
    refreshActiveListenables();
  }

  Future<void> clearImageCache() async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    await PlexImageCacheManager.instance.emptyCache();
  }
}
