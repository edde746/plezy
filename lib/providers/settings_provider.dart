import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsService? _settingsService;
  int _libraryDensity = LibraryDensity.defaultValue;
  ViewMode _viewMode = ViewMode.grid;
  EpisodePosterMode _episodePosterMode = EpisodePosterMode.seriesPoster;
  bool _showHeroSection = true;
  bool _useGlobalHubs = true;
  bool _showServerNameOnHubs = false;
  bool _alwaysKeepSidebarOpen = false;
  bool _showUnwatchedCount = true;
  bool _hideSpoilers = false;
  bool _showNavBarLabels = true;
  bool _liveTvDefaultFavorites = false;
  bool _autoHidePerformanceOverlay = true;
  bool _isInitialized = false;
  Future<void>? _initFuture;

  SettingsProvider() {
    // Start initialization eagerly to reduce race conditions
    _initFuture = _initializeSettings();
  }

  /// Ensures the provider is initialized. Call this before accessing settings
  /// in contexts where you need the actual persisted values.
  Future<void> ensureInitialized() => _initFuture ?? _initializeSettings();

  Future<void> _initializeSettings() async {
    if (_isInitialized) return;

    _settingsService = await SettingsService.getInstance();
    _libraryDensity = _settingsService!.getLibraryDensity();
    _viewMode = _settingsService!.getViewMode();
    _episodePosterMode = _settingsService!.getEpisodePosterMode();
    _showHeroSection = _settingsService!.getShowHeroSection();
    _useGlobalHubs = _settingsService!.getUseGlobalHubs();
    _showServerNameOnHubs = _settingsService!.getShowServerNameOnHubs();
    _alwaysKeepSidebarOpen = _settingsService!.getAlwaysKeepSidebarOpen();
    _showUnwatchedCount = _settingsService!.getShowUnwatchedCount();
    _hideSpoilers = _settingsService!.getHideSpoilers();
    _showNavBarLabels = _settingsService!.getShowNavBarLabels();
    _liveTvDefaultFavorites = _settingsService!.getLiveTvDefaultFavorites();
    _autoHidePerformanceOverlay = _settingsService!.getAutoHidePerformanceOverlay();
    _isInitialized = true;
    notifyListeners();
  }

  /// Whether the provider has completed initialization
  bool get isInitialized => _isInitialized;

  int get libraryDensity => _libraryDensity;

  ViewMode get viewMode => _viewMode;

  EpisodePosterMode get episodePosterMode => _episodePosterMode;

  bool get showHeroSection => _showHeroSection;

  bool get useGlobalHubs => _useGlobalHubs;

  bool get showServerNameOnHubs => _showServerNameOnHubs;

  bool get alwaysKeepSidebarOpen => _alwaysKeepSidebarOpen;

  bool get showUnwatchedCount => _showUnwatchedCount;

  bool get hideSpoilers => _hideSpoilers;

  bool get showNavBarLabels => _showNavBarLabels;

  bool get liveTvDefaultFavorites => _liveTvDefaultFavorites;

  bool get autoHidePerformanceOverlay => _autoHidePerformanceOverlay;

  /// Helper to update a setting: ensures init, deduplicates, persists, notifies.
  Future<void> _updateSetting<T>({
    required T current,
    required T value,
    required void Function(T) setLocal,
    required Future<void> Function(T) persist,
  }) async {
    if (!_isInitialized) await _initializeSettings();
    if (current != value) {
      setLocal(value);
      await persist(value);
      notifyListeners();
    }
  }

  Future<void> setLibraryDensity(int density) => _updateSetting(
    current: _libraryDensity, value: density.clamp(LibraryDensity.min, LibraryDensity.max),
    setLocal: (v) => _libraryDensity = v,
    persist: _settingsService!.setLibraryDensity,
  );

  Future<void> setViewMode(ViewMode mode) => _updateSetting(
    current: _viewMode, value: mode,
    setLocal: (v) => _viewMode = v,
    persist: _settingsService!.setViewMode,
  );

  Future<void> setEpisodePosterMode(EpisodePosterMode mode) => _updateSetting(
    current: _episodePosterMode, value: mode,
    setLocal: (v) => _episodePosterMode = v,
    persist: _settingsService!.setEpisodePosterMode,
  );

  Future<void> setShowHeroSection(bool value) => _updateSetting(
    current: _showHeroSection, value: value,
    setLocal: (v) => _showHeroSection = v,
    persist: _settingsService!.setShowHeroSection,
  );

  Future<void> setUseGlobalHubs(bool value) => _updateSetting(
    current: _useGlobalHubs, value: value,
    setLocal: (v) => _useGlobalHubs = v,
    persist: _settingsService!.setUseGlobalHubs,
  );

  Future<void> setShowServerNameOnHubs(bool value) => _updateSetting(
    current: _showServerNameOnHubs, value: value,
    setLocal: (v) => _showServerNameOnHubs = v,
    persist: _settingsService!.setShowServerNameOnHubs,
  );

  Future<void> setAlwaysKeepSidebarOpen(bool value) => _updateSetting(
    current: _alwaysKeepSidebarOpen, value: value,
    setLocal: (v) => _alwaysKeepSidebarOpen = v,
    persist: _settingsService!.setAlwaysKeepSidebarOpen,
  );

  Future<void> setShowUnwatchedCount(bool value) => _updateSetting(
    current: _showUnwatchedCount, value: value,
    setLocal: (v) => _showUnwatchedCount = v,
    persist: _settingsService!.setShowUnwatchedCount,
  );

  Future<void> setHideSpoilers(bool value) => _updateSetting(
    current: _hideSpoilers, value: value,
    setLocal: (v) => _hideSpoilers = v,
    persist: _settingsService!.setHideSpoilers,
  );

  Future<void> setShowNavBarLabels(bool value) => _updateSetting(
    current: _showNavBarLabels, value: value,
    setLocal: (v) => _showNavBarLabels = v,
    persist: _settingsService!.setShowNavBarLabels,
  );

  Future<void> setLiveTvDefaultFavorites(bool value) => _updateSetting(
    current: _liveTvDefaultFavorites, value: value,
    setLocal: (v) => _liveTvDefaultFavorites = v,
    persist: _settingsService!.setLiveTvDefaultFavorites,
  );

  Future<void> setAutoHidePerformanceOverlay(bool value) => _updateSetting(
    current: _autoHidePerformanceOverlay, value: value,
    setLocal: (v) => _autoHidePerformanceOverlay = v,
    persist: _settingsService!.setAutoHidePerformanceOverlay,
  );

}
