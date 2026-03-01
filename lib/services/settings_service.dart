import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/hotkey_model.dart';
import 'package:plezy/utils/app_logger.dart';
import '../i18n/strings.g.dart';
import '../models/mpv_config_models.dart';
import '../models/external_player_models.dart';
import 'base_shared_preferences_service.dart';
import '../utils/platform_detector.dart';

enum ThemeMode { system, light, dark, oled }

enum LibraryDensity { compact, normal, comfortable }

enum ViewMode { grid, list }

enum EpisodePosterMode { seriesPoster, seasonPoster, episodeThumbnail }

class SettingsService extends BaseSharedPreferencesService {
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyEnableDebugLogging = 'enable_debug_logging';
  static const String _keyBufferSize = 'buffer_size';
  static const String _keyBufferSizeMigratedToAuto = 'buffer_size_migrated_to_auto';
  static const String _keyKeyboardShortcuts = 'keyboard_shortcuts';
  static const String _keyKeyboardHotkeys = 'keyboard_hotkeys';
  static const String _keyEnableHardwareDecoding = 'enable_hardware_decoding';
  static const String _keyEnableHDR = 'enable_hdr';
  static const String _keyPreferredVideoCodec = 'preferred_video_codec';
  static const String _keyPreferredAudioCodec = 'preferred_audio_codec';
  static const String _keyLibraryDensity = 'library_density';
  static const String _keyViewMode = 'view_mode';
  static const String _keyUseSeasonPoster = 'use_season_poster'; // Legacy key for migration
  static const String _keyEpisodePosterMode = 'episode_poster_mode';
  static const String _keySeekTimeSmall = 'seek_time_small';
  static const String _keySeekTimeLarge = 'seek_time_large';
  static const String _keyMediaVersionPreferences = 'media_version_preferences';
  static const String _keyShowHeroSection = 'show_hero_section';
  static const String _keyUseGlobalHubs = 'use_global_hubs';
  static const String _keyShowServerNameOnHubs = 'show_server_name_on_hubs';
  static const String _keySleepTimerDuration = 'sleep_timer_duration';
  static const String _keyAudioSyncOffset = 'audio_sync_offset';
  static const String _keySubtitleSyncOffset = 'subtitle_sync_offset';
  static const String _keyVolume = 'volume';
  static const String _keyRotationLocked = 'rotation_locked';
  static const String _keySubtitleFontSize = 'subtitle_font_size';
  static const String _keySubtitleTextColor = 'subtitle_text_color';
  static const String _keySubtitleBorderSize = 'subtitle_border_size';
  static const String _keySubtitleBorderColor = 'subtitle_border_color';
  static const String _keySubtitleBackgroundColor = 'subtitle_background_color';
  static const String _keySubtitleBackgroundOpacity = 'subtitle_background_opacity';
  static const String _keySubtitlePosition = 'subtitle_position';
  static const String _keyAppLocale = 'app_locale';
  static const String _keyRememberTrackSelections = 'remember_track_selections';
  static const String _keyClickVideoTogglesPlayback = 'click_video_toggles_playback';
  static const String _keyAutoSkipIntro = 'auto_skip_intro';
  static const String _keyAutoSkipCredits = 'auto_skip_credits';
  static const String _keyAutoSkipDelay = 'auto_skip_delay';
  static const String _keyCustomDownloadPath = 'custom_download_path';
  static const String _keyCustomDownloadPathType = 'custom_download_path_type';
  static const String _keyDownloadOnWifiOnly = 'download_on_wifi_only';
  static const String _keyVideoPlayerNavigationEnabled = 'video_player_navigation_enabled';
  static const String _keyShowPerformanceOverlay = 'show_performance_overlay';
  static const String _keyMpvConfigEntries = 'mpv_config_entries';
  static const String _keyMpvConfigPresets = 'mpv_config_presets';
  static const String _keyMaxVolume = 'max_volume';
  static const String _keyEnableDiscordRPC = 'enable_discord_rpc';
  static const String _keyMatchContentFrameRate = 'match_content_frame_rate';
  static const String _keyTunneledPlayback = 'tunneled_playback';
  static const String _keyDefaultPlaybackSpeed = 'default_playback_speed';
  static const String _keyAutoPlayNextEpisode = 'auto_play_next_episode';
  static const String _keyUseExoPlayer = 'use_exoplayer';
  static const String _keyAlwaysKeepSidebarOpen = 'always_keep_sidebar_open';
  static const String _keyShowUnwatchedCount = 'show_unwatched_count';
  static const String _keyHideSpoilers = 'hide_spoilers';
  static const String _keyGlobalShaderPreset = 'global_shader_preset';
  static const String _keyRequireProfileSelectionOnOpen = 'require_profile_selection_on_open';
  static const String _keyUseExternalPlayer = 'use_external_player';
  static const String _keySelectedExternalPlayer = 'selected_external_player';
  static const String _keyCustomExternalPlayers = 'custom_external_players';
  static const String _keyConfirmExitOnBack = 'confirm_exit_on_back';
  static const String _keyAmbientLighting = 'ambient_lighting';
  static const String _keyAudioPassthrough = 'audio_passthrough';
  static const String _keyAudioNormalization = 'audio_normalization';

  SettingsService._();

  static Future<SettingsService> getInstance() {
    return BaseSharedPreferencesService.initializeInstance(() => SettingsService._());
  }

  /// Generic helper to get an enum value from preferences
  T _getEnumValue<T extends Enum>(String key, List<T> values, T defaultValue) {
    final stored = prefs.getString(key);
    if (stored == null) return defaultValue;
    return values.firstWhere((v) => v.name == stored, orElse: () => defaultValue);
  }

  // Theme Mode
  Future<void> setThemeMode(ThemeMode mode) async {
    await prefs.setString(_keyThemeMode, mode.name);
  }

  ThemeMode getThemeMode() {
    final stored = prefs.getString(_keyThemeMode);
    if (stored == null) {
      // Default to OLED on Android TV, system elsewhere
      return TvDetectionService.isTVSync() ? ThemeMode.oled : ThemeMode.system;
    }
    return _getEnumValue(_keyThemeMode, ThemeMode.values, ThemeMode.system);
  }

  // Debug Logging
  Future<void> setEnableDebugLogging(bool enabled) async {
    await prefs.setBool(_keyEnableDebugLogging, enabled);
    // Update logger level immediately when setting changes
    setLoggerLevel(enabled);
  }

  bool getEnableDebugLogging() {
    return prefs.getBool(_keyEnableDebugLogging) ?? false;
  }

  // Buffer Size (in MB)
  Future<void> setBufferSize(int sizeInMB) async {
    await prefs.setInt(_keyBufferSize, sizeInMB);
  }

  int getBufferSize() {
    // One-time migration: reset existing users to Auto.
    // SharedPreferences updates in-memory cache synchronously, so the
    // unawaited disk-flush futures are safe here (idempotent if re-run).
    if (prefs.getBool(_keyBufferSizeMigratedToAuto) != true) {
      prefs.remove(_keyBufferSize);
      prefs.setBool(_keyBufferSizeMigratedToAuto, true);
    }
    return prefs.getInt(_keyBufferSize) ?? 0; // 0 = Auto
  }

  // Hardware Decoding
  Future<void> setEnableHardwareDecoding(bool enabled) async {
    await prefs.setBool(_keyEnableHardwareDecoding, enabled);
  }

  bool getEnableHardwareDecoding() {
    return prefs.getBool(_keyEnableHardwareDecoding) ?? true; // Default enabled
  }

  // HDR (High Dynamic Range)
  Future<void> setEnableHDR(bool enabled) async {
    await prefs.setBool(_keyEnableHDR, enabled);
  }

  bool getEnableHDR() {
    return prefs.getBool(_keyEnableHDR) ?? true; // Default enabled
  }

  // Preferred Video Codec
  Future<void> setPreferredVideoCodec(String codec) async {
    await prefs.setString(_keyPreferredVideoCodec, codec);
  }

  String getPreferredVideoCodec() {
    return prefs.getString(_keyPreferredVideoCodec) ?? 'auto';
  }

  // Preferred Audio Codec
  Future<void> setPreferredAudioCodec(String codec) async {
    await prefs.setString(_keyPreferredAudioCodec, codec);
  }

  String getPreferredAudioCodec() {
    return prefs.getString(_keyPreferredAudioCodec) ?? 'auto';
  }

  // Library Density
  Future<void> setLibraryDensity(LibraryDensity density) async {
    await prefs.setString(_keyLibraryDensity, density.name);
  }

  LibraryDensity getLibraryDensity() {
    return _getEnumValue(_keyLibraryDensity, LibraryDensity.values, LibraryDensity.normal);
  }

  // View Mode
  Future<void> setViewMode(ViewMode mode) async {
    await prefs.setString(_keyViewMode, mode.name);
  }

  ViewMode getViewMode() {
    return _getEnumValue(_keyViewMode, ViewMode.values, ViewMode.grid);
  }

  // Episode Poster Mode
  Future<void> setEpisodePosterMode(EpisodePosterMode mode) async {
    await prefs.setString(_keyEpisodePosterMode, mode.name);
  }

  EpisodePosterMode getEpisodePosterMode() {
    // Migration: check old boolean key first
    final legacyValue = prefs.getBool(_keyUseSeasonPoster);
    if (legacyValue != null) {
      // Migrate old setting: true = seasonPoster, false = seriesPoster
      final migratedMode = legacyValue ? EpisodePosterMode.seasonPoster : EpisodePosterMode.seriesPoster;
      // Clear old key and save new format (fire and forget)
      prefs.remove(_keyUseSeasonPoster);
      prefs.setString(_keyEpisodePosterMode, migratedMode.name);
      return migratedMode;
    }
    return _getEnumValue(_keyEpisodePosterMode, EpisodePosterMode.values, EpisodePosterMode.episodeThumbnail);
  }

  // Show Hero Section
  Future<void> setShowHeroSection(bool enabled) async {
    await prefs.setBool(_keyShowHeroSection, enabled);
  }

  bool getShowHeroSection() {
    return prefs.getBool(_keyShowHeroSection) ?? true; // Default: true (show hero section)
  }

  // Use Global Hubs (true = global /hubs endpoint, false = per-library hubs)
  Future<void> setUseGlobalHubs(bool enabled) async {
    await prefs.setBool(_keyUseGlobalHubs, enabled);
  }

  bool getUseGlobalHubs() {
    return prefs.getBool(_keyUseGlobalHubs) ?? true; // Default: true (use global hubs like official Plex)
  }

  // Show Server Name on Hubs (false = only on duplicates, true = always)
  Future<void> setShowServerNameOnHubs(bool enabled) async {
    await prefs.setBool(_keyShowServerNameOnHubs, enabled);
  }

  bool getShowServerNameOnHubs() {
    return prefs.getBool(_keyShowServerNameOnHubs) ?? false; // Default: false (only show on duplicates)
  }

  // Seek Time Small (in seconds)
  Future<void> setSeekTimeSmall(int seconds) async {
    await prefs.setInt(_keySeekTimeSmall, seconds);
  }

  int getSeekTimeSmall() {
    return prefs.getInt(_keySeekTimeSmall) ?? 10; // Default: 10 seconds
  }

  // Seek Time Large (in seconds)
  Future<void> setSeekTimeLarge(int seconds) async {
    await prefs.setInt(_keySeekTimeLarge, seconds);
  }

  int getSeekTimeLarge() {
    return prefs.getInt(_keySeekTimeLarge) ?? 30; // Default: 30 seconds
  }

  // Sleep Timer Duration (in minutes)
  Future<void> setSleepTimerDuration(int minutes) async {
    await prefs.setInt(_keySleepTimerDuration, minutes);
  }

  int getSleepTimerDuration() {
    return prefs.getInt(_keySleepTimerDuration) ?? 30; // Default: 30 minutes
  }

  // Audio Sync Offset (in milliseconds)
  Future<void> setAudioSyncOffset(int milliseconds) async {
    await prefs.setInt(_keyAudioSyncOffset, milliseconds);
  }

  int getAudioSyncOffset() {
    return prefs.getInt(_keyAudioSyncOffset) ?? 0; // Default: 0ms (no offset)
  }

  // Subtitle Sync Offset (in milliseconds)
  Future<void> setSubtitleSyncOffset(int milliseconds) async {
    await prefs.setInt(_keySubtitleSyncOffset, milliseconds);
  }

  int getSubtitleSyncOffset() {
    return prefs.getInt(_keySubtitleSyncOffset) ?? 0; // Default: 0ms (no offset)
  }

  // Volume (0.0 to 100.0)
  Future<void> setVolume(double volume) async {
    await prefs.setDouble(_keyVolume, volume);
  }

  double getVolume() {
    return prefs.getDouble(_keyVolume) ?? 100.0; // Default: full volume
  }

  // Max Volume (100-300%, for volume boost)
  Future<void> setMaxVolume(int percent) async {
    await prefs.setInt(_keyMaxVolume, percent.clamp(100, 300));
  }

  int getMaxVolume() {
    return prefs.getInt(_keyMaxVolume) ?? 100; // Default: 100% (no boost)
  }

  // Rotation Lock (mobile only)
  Future<void> setRotationLocked(bool locked) async {
    await prefs.setBool(_keyRotationLocked, locked);
  }

  bool getRotationLocked() {
    return prefs.getBool(_keyRotationLocked) ?? true; // Default: locked (landscape only)
  }

  // Subtitle Styling Settings

  // Font Size (30-80, default 55)
  Future<void> setSubtitleFontSize(int size) async {
    await prefs.setInt(_keySubtitleFontSize, size);
  }

  int getSubtitleFontSize() {
    return prefs.getInt(_keySubtitleFontSize) ?? 38;
  }

  // Text Color (hex format #RRGGBB, default white)
  Future<void> setSubtitleTextColor(String color) async {
    await prefs.setString(_keySubtitleTextColor, color);
  }

  String getSubtitleTextColor() {
    return prefs.getString(_keySubtitleTextColor) ?? '#FFFFFF';
  }

  // Border Size (0-5, default 3)
  Future<void> setSubtitleBorderSize(int size) async {
    await prefs.setInt(_keySubtitleBorderSize, size);
  }

  int getSubtitleBorderSize() {
    return prefs.getInt(_keySubtitleBorderSize) ?? 3;
  }

  // Border Color (hex format #RRGGBB, default black)
  Future<void> setSubtitleBorderColor(String color) async {
    await prefs.setString(_keySubtitleBorderColor, color);
  }

  String getSubtitleBorderColor() {
    return prefs.getString(_keySubtitleBorderColor) ?? '#000000';
  }

  // Background Color (hex format #RRGGBB, default black)
  Future<void> setSubtitleBackgroundColor(String color) async {
    await prefs.setString(_keySubtitleBackgroundColor, color);
  }

  String getSubtitleBackgroundColor() {
    return prefs.getString(_keySubtitleBackgroundColor) ?? '#000000';
  }

  // Background Opacity (0-100, default 0 for transparent)
  Future<void> setSubtitleBackgroundOpacity(int opacity) async {
    await prefs.setInt(_keySubtitleBackgroundOpacity, opacity);
  }

  int getSubtitleBackgroundOpacity() {
    return prefs.getInt(_keySubtitleBackgroundOpacity) ?? 0;
  }

  // Subtitle Position (0 = top, 100 = bottom, default 100)
  Future<void> setSubtitlePosition(int position) async {
    await prefs.setInt(_keySubtitlePosition, position.clamp(0, 100));
  }

  int getSubtitlePosition() {
    return prefs.getInt(_keySubtitlePosition) ?? 100; // Default: bottom
  }

  // Keyboard Shortcuts (Legacy String-based)
  Map<String, String> getDefaultKeyboardShortcuts() {
    return {
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
  }

  // HotKey Objects (New implementation)
  Map<String, HotKey> getDefaultKeyboardHotkeys() {
    return {
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
      'speed_increase': const HotKey(key: PhysicalKeyboardKey.equal),
      'speed_decrease': const HotKey(key: PhysicalKeyboardKey.minus),
      'speed_reset': const HotKey(key: PhysicalKeyboardKey.keyR),
      'sub_seek_next': const HotKey(key: PhysicalKeyboardKey.arrowRight, modifiers: [HotKeyModifier.control]),
      'sub_seek_prev': const HotKey(key: PhysicalKeyboardKey.arrowLeft, modifiers: [HotKeyModifier.control]),
      'shader_toggle': const HotKey(key: PhysicalKeyboardKey.keyG),
      'skip_marker': const HotKey(key: PhysicalKeyboardKey.enter),
    };
  }

  Future<void> setKeyboardShortcuts(Map<String, String> shortcuts) async {
    final jsonString = json.encode(shortcuts);
    await prefs.setString(_keyKeyboardShortcuts, jsonString);
  }

  Map<String, String> getKeyboardShortcuts() {
    final jsonString = prefs.getString(_keyKeyboardShortcuts);
    if (jsonString == null) return getDefaultKeyboardShortcuts();

    final decoded = decodeJsonStringToMap(jsonString);
    if (decoded.isEmpty) return getDefaultKeyboardShortcuts();

    final shortcuts = decoded.map((key, value) => MapEntry(key, value.toString()));

    // Merge with defaults to ensure all keys exist
    final defaults = getDefaultKeyboardShortcuts();
    defaults.addAll(shortcuts);
    return defaults;
  }

  Future<void> setKeyboardShortcut(String action, String key) async {
    final shortcuts = getKeyboardShortcuts();
    shortcuts[action] = key;
    await setKeyboardShortcuts(shortcuts);
  }

  String getKeyboardShortcut(String action) {
    final shortcuts = getKeyboardShortcuts();
    return shortcuts[action] ?? '';
  }

  Future<void> resetKeyboardShortcuts() async {
    await setKeyboardShortcuts(getDefaultKeyboardShortcuts());
  }

  // HotKey Objects Methods
  Future<void> setKeyboardHotkeys(Map<String, HotKey> hotkeys) async {
    final Map<String, Map<String, dynamic>> serializedHotkeys = {};
    for (final entry in hotkeys.entries) {
      serializedHotkeys[entry.key] = _serializeHotKey(entry.value);
    }
    final jsonString = json.encode(serializedHotkeys);
    await prefs.setString(_keyKeyboardHotkeys, jsonString);
  }

  Future<Map<String, HotKey>> getKeyboardHotkeys() async {
    final jsonString = prefs.getString(_keyKeyboardHotkeys);
    if (jsonString == null) {
      return getDefaultKeyboardHotkeys();
    }

    try {
      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      final Map<String, HotKey> hotkeys = {};

      for (final entry in decoded.entries) {
        final hotKey = _deserializeHotKey(entry.value as Map<String, dynamic>);
        if (hotKey != null) {
          hotkeys[entry.key] = hotKey;
        }
      }

      // Merge with defaults to ensure all keys exist, but keep saved hotkeys priority
      final defaults = getDefaultKeyboardHotkeys();
      final result = <String, HotKey>{};

      // Start with defaults
      result.addAll(defaults);
      // Override with saved hotkeys (this preserves user customizations)
      result.addAll(hotkeys);

      return result;
    } catch (e) {
      appLogger.d('Failed to parse keyboard hotkeys', error: e);
      return getDefaultKeyboardHotkeys();
    }
  }

  Future<void> setKeyboardHotkey(String action, HotKey hotKey) async {
    final hotkeys = await getKeyboardHotkeys();
    hotkeys[action] = hotKey;
    await setKeyboardHotkeys(hotkeys);
  }

  Future<HotKey?> getKeyboardHotkey(String action) async {
    final hotkeys = await getKeyboardHotkeys();
    return hotkeys[action];
  }

  Future<void> resetKeyboardHotkeys() async {
    await setKeyboardHotkeys(getDefaultKeyboardHotkeys());
  }

  // Video Player Navigation (use arrow keys to navigate video player controls)
  Future<void> setVideoPlayerNavigationEnabled(bool enabled) async {
    await prefs.setBool(_keyVideoPlayerNavigationEnabled, enabled);
  }

  bool getVideoPlayerNavigationEnabled() {
    // Default: enabled on Android TV, disabled elsewhere
    return prefs.getBool(_keyVideoPlayerNavigationEnabled) ?? TvDetectionService.isTVSync();
  }

  // Performance Overlay (show debug stats on video player)
  Future<void> setShowPerformanceOverlay(bool enabled) async {
    await prefs.setBool(_keyShowPerformanceOverlay, enabled);
  }

  bool getShowPerformanceOverlay() {
    return prefs.getBool(_keyShowPerformanceOverlay) ?? false; // Default: disabled
  }

  // Helper methods for HotKey serialization
  static const _modifierMap = <String, HotKeyModifier>{
    'alt': HotKeyModifier.alt,
    'control': HotKeyModifier.control,
    'shift': HotKeyModifier.shift,
    'meta': HotKeyModifier.meta,
    'capsLock': HotKeyModifier.capsLock,
    'fn': HotKeyModifier.fn,
  };

  Map<String, dynamic> _serializeHotKey(HotKey hotKey) {
    // Use USB HID code for reliable serialization across debug/release modes
    final usbHidCode = hotKey.key.usbHidUsage.toRadixString(16).padLeft(8, '0');
    return {'key': usbHidCode, 'modifiers': hotKey.modifiers?.map((m) => m.name).toList() ?? []};
  }

  HotKey? _deserializeHotKey(Map<String, dynamic> data) {
    try {
      final keyString = data['key'] as String;
      final modifierNames = (data['modifiers'] as List<dynamic>).cast<String>();

      final modifiers = modifierNames
          .map((name) => _modifierMap[name])
          .where((m) => m != null)
          .cast<HotKeyModifier>()
          .toList();

      // Try direct USB HID lookup first (new format), fall back to string parsing (backwards compat)
      final key = _usbHidKeyMap[keyString] ?? _findKeyByString(keyString);
      if (key != null) {
        return HotKey(key: key, modifiers: modifiers.isNotEmpty ? modifiers : null);
      }
    } catch (e) {
      // Ignore deserialization errors
    }
    return null;
  }

  // Unified map for USB HID codes to PhysicalKeyboardKey
  static const _usbHidKeyMap = <String, PhysicalKeyboardKey>{
    // Special keys
    '0007002c': PhysicalKeyboardKey.space,
    '0007002a': PhysicalKeyboardKey.backspace,
    '0007004c': PhysicalKeyboardKey.delete,
    '00070028': PhysicalKeyboardKey.enter,
    '00070029': PhysicalKeyboardKey.escape,
    '0007002b': PhysicalKeyboardKey.tab,
    '00070039': PhysicalKeyboardKey.capsLock,
    // Arrow keys
    '00070050': PhysicalKeyboardKey.arrowLeft,
    '00070052': PhysicalKeyboardKey.arrowUp,
    '0007004f': PhysicalKeyboardKey.arrowRight,
    '00070051': PhysicalKeyboardKey.arrowDown,
    // Navigation keys
    '0007004a': PhysicalKeyboardKey.home,
    '0007004d': PhysicalKeyboardKey.end,
    '0007004b': PhysicalKeyboardKey.pageUp,
    '0007004e': PhysicalKeyboardKey.pageDown,
    // Symbol keys
    '0007002d': PhysicalKeyboardKey.equal,
    '0007002e': PhysicalKeyboardKey.minus,
    // Function keys
    '0007003a': PhysicalKeyboardKey.f1,
    '0007003b': PhysicalKeyboardKey.f2,
    '0007003c': PhysicalKeyboardKey.f3,
    '0007003d': PhysicalKeyboardKey.f4,
    '0007003e': PhysicalKeyboardKey.f5,
    '0007003f': PhysicalKeyboardKey.f6,
    '00070040': PhysicalKeyboardKey.f7,
    '00070041': PhysicalKeyboardKey.f8,
    '00070042': PhysicalKeyboardKey.f9,
    '00070043': PhysicalKeyboardKey.f10,
    '00070044': PhysicalKeyboardKey.f11,
    '00070045': PhysicalKeyboardKey.f12,
    // Number keys
    '00070027': PhysicalKeyboardKey.digit0,
    '0007001e': PhysicalKeyboardKey.digit1,
    '0007001f': PhysicalKeyboardKey.digit2,
    '00070020': PhysicalKeyboardKey.digit3,
    '00070021': PhysicalKeyboardKey.digit4,
    '00070022': PhysicalKeyboardKey.digit5,
    '00070023': PhysicalKeyboardKey.digit6,
    '00070024': PhysicalKeyboardKey.digit7,
    '00070025': PhysicalKeyboardKey.digit8,
    '00070026': PhysicalKeyboardKey.digit9,
    // Letter keys
    '00070004': PhysicalKeyboardKey.keyA,
    '00070005': PhysicalKeyboardKey.keyB,
    '00070006': PhysicalKeyboardKey.keyC,
    '00070007': PhysicalKeyboardKey.keyD,
    '00070008': PhysicalKeyboardKey.keyE,
    '00070009': PhysicalKeyboardKey.keyF,
    '0007000a': PhysicalKeyboardKey.keyG,
    '0007000b': PhysicalKeyboardKey.keyH,
    '0007000c': PhysicalKeyboardKey.keyI,
    '0007000d': PhysicalKeyboardKey.keyJ,
    '0007000e': PhysicalKeyboardKey.keyK,
    '0007000f': PhysicalKeyboardKey.keyL,
    '00070010': PhysicalKeyboardKey.keyM,
    '00070011': PhysicalKeyboardKey.keyN,
    '00070012': PhysicalKeyboardKey.keyO,
    '00070013': PhysicalKeyboardKey.keyP,
    '00070014': PhysicalKeyboardKey.keyQ,
    '00070015': PhysicalKeyboardKey.keyR,
    '00070016': PhysicalKeyboardKey.keyS,
    '00070017': PhysicalKeyboardKey.keyT,
    '00070018': PhysicalKeyboardKey.keyU,
    '00070019': PhysicalKeyboardKey.keyV,
    '0007001a': PhysicalKeyboardKey.keyW,
    '0007001b': PhysicalKeyboardKey.keyX,
    '0007001c': PhysicalKeyboardKey.keyY,
    '0007001d': PhysicalKeyboardKey.keyZ,
  };

  // Map for pattern-based key name matching (lowercase keys for case-insensitive matching)
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

  // Function keys map
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

  // Digit keys map
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

  // Letter keys map
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

  // Helper method to find PhysicalKeyboardKey by string representation
  PhysicalKeyboardKey? _findKeyByString(String keyString) {
    final normalized = keyString.toLowerCase();

    // Try extracting USB HID code from toString() output
    // Format: PhysicalKeyboardKey#ec9ed(usbHidUsage: "0x0007002c", debugName: "Space")
    final usbHidMatch = RegExp(r'usbhidusage: "0x([0-9a-f]+)"').firstMatch(normalized);
    if (usbHidMatch != null) {
      final usbHidCode = usbHidMatch.group(1)!;
      final key = _usbHidKeyMap[usbHidCode];
      if (key != null) return key;
    }

    // Try direct name matches
    for (final entry in _keyNameMap.entries) {
      if (normalized.contains(entry.key)) {
        return entry.value;
      }
    }

    // Try function keys (check longer patterns first to avoid f1 matching f10)
    for (final entry in _functionKeyMap.entries) {
      if (normalized.contains(entry.key)) {
        return entry.value;
      }
    }

    // Try digit keys
    for (final entry in _digitKeyMap.entries) {
      if (normalized.contains(entry.key)) {
        return entry.value;
      }
    }

    // Try letter keys
    for (final entry in _letterKeyMap.entries) {
      if (normalized.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  // Media Version Preferences
  /// Save media version preference for a series
  /// [seriesRatingKey] is the grandparentRatingKey for TV series, or ratingKey for movies
  /// [mediaIndex] is the index of the selected media version
  Future<void> setMediaVersionPreference(String seriesRatingKey, int mediaIndex) async {
    final preferences = _getMediaVersionPreferences();
    preferences[seriesRatingKey] = mediaIndex;

    final jsonString = json.encode(preferences);
    await prefs.setString(_keyMediaVersionPreferences, jsonString);
  }

  /// Get saved media version preference for a series
  /// Returns null if no preference is saved
  int? getMediaVersionPreference(String seriesRatingKey) {
    final preferences = _getMediaVersionPreferences();
    return preferences[seriesRatingKey];
  }

  /// Clear media version preference for a series
  Future<void> clearMediaVersionPreference(String seriesRatingKey) async {
    final preferences = _getMediaVersionPreferences();
    preferences.remove(seriesRatingKey);

    final jsonString = json.encode(preferences);
    await prefs.setString(_keyMediaVersionPreferences, jsonString);
  }

  /// Get all media version preferences
  Map<String, int> _getMediaVersionPreferences() {
    final jsonString = prefs.getString(_keyMediaVersionPreferences);
    if (jsonString == null) return {};

    final decoded = decodeJsonStringToMap(jsonString);
    return decoded.map((key, value) => MapEntry(key, value as int));
  }

  // App Locale
  Future<void> setAppLocale(AppLocale locale) async {
    await prefs.setString(_keyAppLocale, locale.languageCode);
  }

  AppLocale getAppLocale() {
    final localeString = prefs.getString(_keyAppLocale);
    if (localeString == null) return AppLocaleUtils.findDeviceLocale();

    return AppLocale.values.asNameMap()[localeString] ?? AppLocale.en;
  }

  // Track Selection Settings

  /// Remember Track Selections - Save per-media audio/subtitle language preferences
  Future<void> setRememberTrackSelections(bool value) async {
    await prefs.setBool(_keyRememberTrackSelections, value);
  }

  bool getRememberTrackSelections() {
    return prefs.getBool(_keyRememberTrackSelections) ?? true;
  }

  // Click on Video Player Settings
  Future<void> setClickVideoTogglesPlayback(bool value) async {
    await prefs.setBool(_keyClickVideoTogglesPlayback, value);
  }

  bool getClickVideoTogglesPlayback() {
    return prefs.getBool(_keyClickVideoTogglesPlayback) ?? false;
  }

  // Auto Skip Intro
  Future<void> setAutoSkipIntro(bool value) async {
    await prefs.setBool(_keyAutoSkipIntro, value);
  }

  bool getAutoSkipIntro() {
    return prefs.getBool(_keyAutoSkipIntro) ?? false; // Default: disabled
  }

  // Auto Skip Credits
  Future<void> setAutoSkipCredits(bool value) async {
    await prefs.setBool(_keyAutoSkipCredits, value);
  }

  bool getAutoSkipCredits() {
    return prefs.getBool(_keyAutoSkipCredits) ?? false; // Default: disabled
  }

  // Auto Skip Delay (in seconds)
  Future<void> setAutoSkipDelay(int seconds) async {
    await prefs.setInt(_keyAutoSkipDelay, seconds);
  }

  int getAutoSkipDelay() {
    return prefs.getInt(_keyAutoSkipDelay) ?? 5; // Default: 5 seconds
  }

  // Custom Download Path
  Future<void> setCustomDownloadPath(String? path, {String type = 'file'}) async {
    if (path == null) {
      await prefs.remove(_keyCustomDownloadPath);
      await prefs.remove(_keyCustomDownloadPathType);
    } else {
      await prefs.setString(_keyCustomDownloadPath, path);
      await prefs.setString(_keyCustomDownloadPathType, type);
    }
  }

  String? getCustomDownloadPath() {
    return prefs.getString(_keyCustomDownloadPath);
  }

  String getCustomDownloadPathType() {
    return prefs.getString(_keyCustomDownloadPathType) ?? 'file';
  }

  bool hasCustomDownloadPath() {
    return prefs.containsKey(_keyCustomDownloadPath);
  }

  // Download on WiFi Only
  Future<void> setDownloadOnWifiOnly(bool value) async {
    await prefs.setBool(_keyDownloadOnWifiOnly, value);
  }

  bool getDownloadOnWifiOnly() {
    return prefs.getBool(_keyDownloadOnWifiOnly) ?? false;
  }

  // MPV Config Entries

  /// Get all MPV config entries
  List<MpvConfigEntry> getMpvConfigEntries() {
    final jsonString = prefs.getString(_keyMpvConfigEntries);
    if (jsonString == null) return [];

    try {
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.map((e) => MpvConfigEntry.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Save all MPV config entries
  Future<void> setMpvConfigEntries(List<MpvConfigEntry> entries) async {
    final jsonString = json.encode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_keyMpvConfigEntries, jsonString);
  }

  /// Get only enabled MPV config entries (for player initialization)
  Map<String, String> getEnabledMpvConfigEntries() {
    final entries = getMpvConfigEntries();
    return Map.fromEntries(entries.where((e) => e.isEnabled).map((e) => MapEntry(e.key, e.value)));
  }

  // MPV Presets

  /// Get all saved presets
  List<MpvPreset> getMpvPresets() {
    final jsonString = prefs.getString(_keyMpvConfigPresets);
    if (jsonString == null) return [];

    try {
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.map((e) => MpvPreset.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Save a new preset (overwrites existing with same name)
  Future<void> saveMpvPreset(String name, List<MpvConfigEntry> entries) async {
    final presets = getMpvPresets();

    // Remove existing preset with same name
    presets.removeWhere((p) => p.name == name);

    presets.add(MpvPreset(name: name, entries: entries, createdAt: DateTime.now()));

    final jsonString = json.encode(presets.map((p) => p.toJson()).toList());
    await prefs.setString(_keyMpvConfigPresets, jsonString);
  }

  /// Delete a preset by name
  Future<void> deleteMpvPreset(String name) async {
    final presets = getMpvPresets();
    presets.removeWhere((p) => p.name == name);

    final jsonString = json.encode(presets.map((p) => p.toJson()).toList());
    await prefs.setString(_keyMpvConfigPresets, jsonString);
  }

  /// Load a preset (replaces current entries)
  Future<void> loadMpvPreset(String name) async {
    final presets = getMpvPresets();
    final preset = presets.firstWhere((p) => p.name == name, orElse: () => throw Exception('Preset not found: $name'));

    await setMpvConfigEntries(preset.entries);
  }

  // Discord Rich Presence
  Future<void> setEnableDiscordRPC(bool enabled) async {
    await prefs.setBool(_keyEnableDiscordRPC, enabled);
  }

  bool getEnableDiscordRPC() {
    return prefs.getBool(_keyEnableDiscordRPC) ?? false; // Default disabled
  }

  // Match Content Frame Rate (Android only)
  Future<void> setMatchContentFrameRate(bool enabled) async {
    await prefs.setBool(_keyMatchContentFrameRate, enabled);
  }

  bool getMatchContentFrameRate() {
    return prefs.getBool(_keyMatchContentFrameRate) ?? false; // Default disabled
  }

  // Tunneled Playback (Android ExoPlayer only)
  Future<void> setTunneledPlayback(bool enabled) async {
    await prefs.setBool(_keyTunneledPlayback, enabled);
  }

  bool getTunneledPlayback() {
    return prefs.getBool(_keyTunneledPlayback) ?? true; // Default: enabled
  }

  // Default Playback Speed (0.5 to 3.0)
  Future<void> setDefaultPlaybackSpeed(double speed) async {
    await prefs.setDouble(_keyDefaultPlaybackSpeed, speed.clamp(0.5, 3.0));
  }

  double getDefaultPlaybackSpeed() {
    return prefs.getDouble(_keyDefaultPlaybackSpeed) ?? 1.0; // Default: normal speed
  }

  // Auto-Play Next Episode
  Future<void> setAutoPlayNextEpisode(bool enabled) async {
    await prefs.setBool(_keyAutoPlayNextEpisode, enabled);
  }

  bool getAutoPlayNextEpisode() {
    return prefs.getBool(_keyAutoPlayNextEpisode) ?? true; // Default enabled
  }

  // Use ExoPlayer on Android (default: true)
  // When false, uses MPV as the player backend
  Future<void> setUseExoPlayer(bool enabled) async {
    await prefs.setBool(_keyUseExoPlayer, enabled);
  }

  bool getUseExoPlayer() {
    return prefs.getBool(_keyUseExoPlayer) ?? true; // Default: ExoPlayer
  }

  // Always Keep Sidebar Open (Desktop/TV only)
  Future<void> setAlwaysKeepSidebarOpen(bool enabled) async {
    await prefs.setBool(_keyAlwaysKeepSidebarOpen, enabled);
  }

  bool getAlwaysKeepSidebarOpen() {
    return prefs.getBool(_keyAlwaysKeepSidebarOpen) ?? false; // Default: collapsed
  }

  // Show Unwatched Count (show unwatched episode count on shows/seasons)
  Future<void> setShowUnwatchedCount(bool enabled) async {
    await prefs.setBool(_keyShowUnwatchedCount, enabled);
  }

  bool getShowUnwatchedCount() {
    return prefs.getBool(_keyShowUnwatchedCount) ?? true; // Default: enabled (show counts)
  }

  // Hide Spoilers (blur thumbnails and hide descriptions for unwatched episodes)
  Future<void> setHideSpoilers(bool enabled) async {
    await prefs.setBool(_keyHideSpoilers, enabled);
  }

  bool getHideSpoilers() {
    return prefs.getBool(_keyHideSpoilers) ?? false; // Default: disabled
  }

  // Global Shader Preset (for MPV video enhancement)
  Future<void> setGlobalShaderPreset(String presetId) async {
    await prefs.setString(_keyGlobalShaderPreset, presetId);
  }

  String getGlobalShaderPreset() {
    return prefs.getString(_keyGlobalShaderPreset) ?? 'none'; // Default: no shader
  }

  // Require Profile Selection on App Open
  Future<void> setRequireProfileSelectionOnOpen(bool enabled) async {
    await prefs.setBool(_keyRequireProfileSelectionOnOpen, enabled);
  }

  bool getRequireProfileSelectionOnOpen() {
    return prefs.getBool(_keyRequireProfileSelectionOnOpen) ?? false;
  }

  // External Player
  Future<void> setUseExternalPlayer(bool enabled) async {
    await prefs.setBool(_keyUseExternalPlayer, enabled);
  }

  bool getUseExternalPlayer() {
    return prefs.getBool(_keyUseExternalPlayer) ?? false;
  }

  Future<void> setSelectedExternalPlayer(ExternalPlayer player) async {
    await prefs.setString(_keySelectedExternalPlayer, player.toJsonString());
  }

  ExternalPlayer getSelectedExternalPlayer() {
    final jsonString = prefs.getString(_keySelectedExternalPlayer);
    if (jsonString == null) return KnownPlayers.systemDefault;
    try {
      return ExternalPlayer.fromJsonString(jsonString);
    } catch (e) {
      appLogger.d('Failed to parse external player', error: e);
      return KnownPlayers.systemDefault;
    }
  }

  Future<void> setCustomExternalPlayers(List<ExternalPlayer> players) async {
    final jsonString = json.encode(players.map((p) => p.toJson()).toList());
    await prefs.setString(_keyCustomExternalPlayers, jsonString);
  }

  List<ExternalPlayer> getCustomExternalPlayers() {
    final jsonString = prefs.getString(_keyCustomExternalPlayers);
    if (jsonString == null) return [];
    try {
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.map((e) => ExternalPlayer.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      appLogger.d('Failed to parse custom external players', error: e);
      return [];
    }
  }

  Future<void> addCustomExternalPlayer(ExternalPlayer player) async {
    final players = getCustomExternalPlayers();
    players.add(player);
    await setCustomExternalPlayers(players);
  }

  Future<void> removeCustomExternalPlayer(String id) async {
    final players = getCustomExternalPlayers();
    players.removeWhere((p) => p.id == id);
    await setCustomExternalPlayers(players);
    // If the removed player was selected, reset to system default
    if (getSelectedExternalPlayer().id == id) {
      await setSelectedExternalPlayer(KnownPlayers.systemDefault);
    }
  }

  // Confirm Exit on Back (Android TV)
  Future<void> setConfirmExitOnBack(bool value) async {
    await prefs.setBool(_keyConfirmExitOnBack, value);
  }

  bool getConfirmExitOnBack() {
    return prefs.getBool(_keyConfirmExitOnBack) ?? true; // Default: enabled
  }

  // Ambient Lighting
  Future<void> setAmbientLighting(bool enabled) async {
    await prefs.setBool(_keyAmbientLighting, enabled);
  }

  bool getAmbientLighting() {
    return prefs.getBool(_keyAmbientLighting) ?? false;
  }

  // Audio Passthrough
  Future<void> setAudioPassthrough(bool enabled) async {
    await prefs.setBool(_keyAudioPassthrough, enabled);
  }

  bool getAudioPassthrough() {
    return prefs.getBool(_keyAudioPassthrough) ?? false;
  }

  // Audio Normalization
  Future<void> setAudioNormalization(bool enabled) async {
    await prefs.setBool(_keyAudioNormalization, enabled);
  }

  bool getAudioNormalization() {
    return prefs.getBool(_keyAudioNormalization) ?? false;
  }

  // Reset all settings to defaults
  Future<void> resetAllSettings() async {
    await Future.wait([
      prefs.remove(_keyThemeMode),
      prefs.remove(_keyEnableDebugLogging),
      prefs.remove(_keyBufferSize),
      prefs.remove(_keyKeyboardShortcuts),
      prefs.remove(_keyKeyboardHotkeys),
      prefs.remove(_keyEnableHardwareDecoding),
      prefs.remove(_keyEnableHDR),
      prefs.remove(_keyPreferredVideoCodec),
      prefs.remove(_keyPreferredAudioCodec),
      prefs.remove(_keyLibraryDensity),
      prefs.remove(_keyViewMode),
      prefs.remove(_keyUseSeasonPoster), // Legacy key
      prefs.remove(_keyEpisodePosterMode),
      prefs.remove(_keyShowHeroSection),
      prefs.remove(_keySeekTimeSmall),
      prefs.remove(_keySeekTimeLarge),
      prefs.remove(_keyMediaVersionPreferences),
      prefs.remove(_keySleepTimerDuration),
      prefs.remove(_keyAudioSyncOffset),
      prefs.remove(_keySubtitleSyncOffset),
      prefs.remove(_keyVolume),
      prefs.remove(_keyMaxVolume),
      prefs.remove(_keySubtitleFontSize),
      prefs.remove(_keySubtitleTextColor),
      prefs.remove(_keySubtitleBorderSize),
      prefs.remove(_keySubtitleBorderColor),
      prefs.remove(_keySubtitleBackgroundColor),
      prefs.remove(_keySubtitleBackgroundOpacity),
      prefs.remove(_keySubtitlePosition),
      prefs.remove(_keyAppLocale),
      prefs.remove(_keyRememberTrackSelections),
      prefs.remove(_keyCustomDownloadPath),
      prefs.remove(_keyCustomDownloadPathType),
      prefs.remove(_keyDownloadOnWifiOnly),
      prefs.remove(_keyVideoPlayerNavigationEnabled),
      prefs.remove(_keyShowPerformanceOverlay),
      prefs.remove(_keyMpvConfigEntries),
      prefs.remove(_keyMpvConfigPresets),
      prefs.remove(_keyEnableDiscordRPC),
      prefs.remove(_keyMatchContentFrameRate),
      prefs.remove(_keyTunneledPlayback),
      prefs.remove(_keyDefaultPlaybackSpeed),
      prefs.remove(_keyAutoPlayNextEpisode),
      prefs.remove(_keyUseExoPlayer),
      prefs.remove(_keyAlwaysKeepSidebarOpen),
      prefs.remove(_keyShowUnwatchedCount),
      prefs.remove(_keyHideSpoilers),
      prefs.remove(_keyGlobalShaderPreset),
      prefs.remove(_keyRequireProfileSelectionOnOpen),
      prefs.remove(_keyUseExternalPlayer),
      prefs.remove(_keySelectedExternalPlayer),
      prefs.remove(_keyCustomExternalPlayers),
      prefs.remove(_keyConfirmExitOnBack),
      prefs.remove(_keyAmbientLighting),
      prefs.remove(_keyAudioPassthrough),
      prefs.remove(_keyAudioNormalization),
      prefs.remove(_keyBufferSizeMigratedToAuto),
    ]);
  }

  // Clear cache (for storage cleanup)
  Future<void> clearCache() async {
    // This would be expanded to clear various cache directories
    // For now, we'll just clear any cache-related preferences
    await Future.wait([
      // Add cache clearing logic here
    ]);
  }

  // Get all settings as a map for debugging/export
  Future<Map<String, dynamic>> getAllSettings() async {
    final hotkeys = await getKeyboardHotkeys();
    return {
      'themeMode': getThemeMode().name,
      'enableDebugLogging': getEnableDebugLogging(),
      'bufferSize': getBufferSize(),
      'enableHardwareDecoding': getEnableHardwareDecoding(),
      'preferredVideoCodec': getPreferredVideoCodec(),
      'preferredAudioCodec': getPreferredAudioCodec(),
      'libraryDensity': getLibraryDensity().name,
      'viewMode': getViewMode().name,
      'episodePosterMode': getEpisodePosterMode().name,
      'seekTimeSmall': getSeekTimeSmall(),
      'seekTimeLarge': getSeekTimeLarge(),
      'keyboardShortcuts': getKeyboardShortcuts(),
      'keyboardHotkeys': hotkeys.map((key, value) => MapEntry(key, _serializeHotKey(value))),
      'rememberTrackSelections': getRememberTrackSelections(),
      'clickVideoTogglesPlayback': getClickVideoTogglesPlayback(),
      'autoSkipIntro': getAutoSkipIntro(),
      'autoSkipCredits': getAutoSkipCredits(),
      'autoSkipDelay': getAutoSkipDelay(),
    };
  }
}
