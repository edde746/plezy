import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsService? _settingsService;
  LibraryDensity _libraryDensity = LibraryDensity.normal;
  ViewMode _viewMode = ViewMode.grid;
  bool _useSeasonPoster = false;
  bool _showHeroSection = true;
  bool _isInitialized = false;

  SettingsProvider() {
    // Don't initialize immediately if lazy-loaded
    // _initializeSettings() will be called when first accessed
  }

  Future<void> _initializeSettings() async {
    if (_isInitialized) return;

    _settingsService = await SettingsService.getInstance();
    _libraryDensity = _settingsService!.getLibraryDensity();
    _viewMode = _settingsService!.getViewMode();
    _useSeasonPoster = _settingsService!.getUseSeasonPoster();
    _showHeroSection = _settingsService!.getShowHeroSection();
    _isInitialized = true;
    notifyListeners();
  }

  LibraryDensity get libraryDensity {
    if (!_isInitialized) _initializeSettings();
    return _libraryDensity;
  }

  ViewMode get viewMode {
    if (!_isInitialized) _initializeSettings();
    return _viewMode;
  }

  bool get useSeasonPoster {
    if (!_isInitialized) _initializeSettings();
    return _useSeasonPoster;
  }

  bool get showHeroSection {
    if (!_isInitialized) _initializeSettings();
    return _showHeroSection;
  }

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

  Future<void> setUseSeasonPoster(bool value) async {
    if (!_isInitialized) await _initializeSettings();
    if (_useSeasonPoster != value) {
      _useSeasonPoster = value;
      await _settingsService!.setUseSeasonPoster(value);
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
}
