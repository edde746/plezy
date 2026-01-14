import 'package:flutter/material.dart';
import '../i18n/strings.g.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsService? _settingsService;
  LibraryDensity _libraryDensity = LibraryDensity.normal;
  ViewMode _viewMode = ViewMode.grid;
  EpisodePosterMode _episodePosterMode = EpisodePosterMode.seriesPoster;
  bool _showHeroSection = true;
  bool _useGlobalHubs = true;
  bool _showServerNameOnHubs = false;
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
    _isInitialized = true;
    notifyListeners();
  }

  /// Whether the provider has completed initialization
  bool get isInitialized => _isInitialized;

  LibraryDensity get libraryDensity => _libraryDensity;

  ViewMode get viewMode => _viewMode;

  EpisodePosterMode get episodePosterMode => _episodePosterMode;

  bool get showHeroSection => _showHeroSection;

  bool get useGlobalHubs => _useGlobalHubs;

  bool get showServerNameOnHubs => _showServerNameOnHubs;

  Future<void> setLibraryDensity(LibraryDensity density) async {
    if (!_isInitialized) await _initializeSettings();
    if (_libraryDensity != density) {
      _libraryDensity = density;
      await _settingsService!.setLibraryDensity(density);
      notifyListeners();
    }
  }

  Future<void> setViewMode(ViewMode mode) async {
    if (!_isInitialized) await _initializeSettings();
    if (_viewMode != mode) {
      _viewMode = mode;
      await _settingsService!.setViewMode(mode);
      notifyListeners();
    }
  }

  Future<void> setEpisodePosterMode(EpisodePosterMode mode) async {
    if (!_isInitialized) await _initializeSettings();
    if (_episodePosterMode != mode) {
      _episodePosterMode = mode;
      await _settingsService!.setEpisodePosterMode(mode);
      notifyListeners();
    }
  }

  Future<void> setShowHeroSection(bool value) async {
    if (!_isInitialized) await _initializeSettings();
    if (_showHeroSection != value) {
      _showHeroSection = value;
      await _settingsService!.setShowHeroSection(value);
      notifyListeners();
    }
  }

  Future<void> setUseGlobalHubs(bool value) async {
    if (!_isInitialized) await _initializeSettings();
    if (_useGlobalHubs != value) {
      _useGlobalHubs = value;
      await _settingsService!.setUseGlobalHubs(value);
      notifyListeners();
    }
  }

  Future<void> setShowServerNameOnHubs(bool value) async {
    if (!_isInitialized) await _initializeSettings();
    if (_showServerNameOnHubs != value) {
      _showServerNameOnHubs = value;
      await _settingsService!.setShowServerNameOnHubs(value);
      notifyListeners();
    }
  }

  String get libraryDensityDisplayName {
    switch (_libraryDensity) {
      case LibraryDensity.compact:
        return 'Compact';
      case LibraryDensity.normal:
        return 'Normal';
      case LibraryDensity.comfortable:
        return 'Comfortable';
    }
  }

  String get episodePosterModeDisplayName {
    switch (_episodePosterMode) {
      case EpisodePosterMode.seriesPoster:
        return t.settings.seriesPoster;
      case EpisodePosterMode.seasonPoster:
        return t.settings.seasonPoster;
      case EpisodePosterMode.episodeThumbnail:
        return t.settings.episodeThumbnail;
    }
  }
}
