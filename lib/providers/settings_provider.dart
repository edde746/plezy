import 'package:flutter/material.dart';
import '../models/transcode_quality_preset.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsService? _settingsService;
  bool _isInitialized = false;
  Future<void>? _initFuture;

  SettingsProvider() {
    _initFuture = _initializeSettings();
  }

  Future<void> ensureInitialized() => _initFuture ?? _initializeSettings();

  bool get isReady => _isInitialized;
  bool get isInitialized => _isInitialized;
  Future<void> get ready => _initFuture ?? Future.value();

  Future<void> _initializeSettings() async {
    if (_isInitialized) return;
    _settingsService = await SettingsService.getInstance();
    _isInitialized = true;
    notifyListeners();
  }

  /// Re-read settings after an external mutation (import, reset). The provider
  /// no longer caches values, so this just re-fetches the service instance and
  /// notifies listeners.
  Future<void> reload() async {
    _settingsService = await SettingsService.getInstance();
    _isInitialized = true;
    notifyListeners();
  }

  T _read<T>(Pref<T> pref, T fallback) => _isInitialized ? _settingsService!.read(pref) : fallback;

  Future<void> _set<T>(Pref<T> pref, T value) async {
    if (!_isInitialized) await _initializeSettings();
    if (_settingsService!.read(pref) == value) return;
    await _settingsService!.write(pref, value);
    notifyListeners();
  }

  int get libraryDensity => _read(SettingsService.libraryDensity, LibraryDensity.defaultValue);
  ViewMode get viewMode => _read(SettingsService.viewMode, ViewMode.grid);
  EpisodePosterMode get episodePosterMode =>
      _read(SettingsService.episodePosterMode, EpisodePosterMode.episodeThumbnail);
  bool get showHeroSection => _read(SettingsService.showHeroSection, true);
  bool get useGlobalHubs => _read(SettingsService.useGlobalHubs, true);
  bool get showServerNameOnHubs => _read(SettingsService.showServerNameOnHubs, false);
  bool get groupLibrariesByServer => _read(SettingsService.groupLibrariesByServer, true);
  bool get alwaysKeepSidebarOpen => _read(SettingsService.alwaysKeepSidebarOpen, false);
  bool get showUnwatchedCount => _read(SettingsService.showUnwatchedCount, true);
  bool get showEpisodeNumberOnCards => _read(SettingsService.showEpisodeNumberOnCards, true);
  bool get hideSpoilers => _read(SettingsService.hideSpoilers, false);
  bool get showNavBarLabels => _read(SettingsService.showNavBarLabels, true);
  bool get liveTvDefaultFavorites => _read(SettingsService.liveTvDefaultFavorites, false);
  bool get autoHidePerformanceOverlay => _read(SettingsService.autoHidePerformanceOverlay, true);
  TranscodeQualityPreset get defaultQualityPreset =>
      TranscodeQualityPreset.fromStorage(_read(SettingsService.defaultQualityPreset, 'original'));

  Future<void> setLibraryDensity(int density) =>
      _set(SettingsService.libraryDensity, density.clamp(LibraryDensity.min, LibraryDensity.max));
  Future<void> setViewMode(ViewMode mode) => _set(SettingsService.viewMode, mode);
  Future<void> setEpisodePosterMode(EpisodePosterMode mode) => _set(SettingsService.episodePosterMode, mode);
  Future<void> setShowHeroSection(bool value) => _set(SettingsService.showHeroSection, value);
  Future<void> setUseGlobalHubs(bool value) => _set(SettingsService.useGlobalHubs, value);
  Future<void> setShowServerNameOnHubs(bool value) => _set(SettingsService.showServerNameOnHubs, value);
  Future<void> setGroupLibrariesByServer(bool value) => _set(SettingsService.groupLibrariesByServer, value);
  Future<void> setAlwaysKeepSidebarOpen(bool value) => _set(SettingsService.alwaysKeepSidebarOpen, value);
  Future<void> setShowUnwatchedCount(bool value) => _set(SettingsService.showUnwatchedCount, value);
  Future<void> setShowEpisodeNumberOnCards(bool value) => _set(SettingsService.showEpisodeNumberOnCards, value);
  Future<void> setHideSpoilers(bool value) => _set(SettingsService.hideSpoilers, value);
  Future<void> setShowNavBarLabels(bool value) => _set(SettingsService.showNavBarLabels, value);
  Future<void> setLiveTvDefaultFavorites(bool value) => _set(SettingsService.liveTvDefaultFavorites, value);
  Future<void> setAutoHidePerformanceOverlay(bool value) => _set(SettingsService.autoHidePerformanceOverlay, value);
  Future<void> setDefaultQualityPreset(TranscodeQualityPreset preset) =>
      _set(SettingsService.defaultQualityPreset, preset.storageKey);
}
