import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  late SettingsService _settingsService;
  LibraryDensity _libraryDensity = LibraryDensity.normal;
  bool _useSeasonPoster = false;
  bool _showHeroSection = true;

  SettingsProvider() {
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    _settingsService = await SettingsService.getInstance();
    _libraryDensity = _settingsService.getLibraryDensity();
    _useSeasonPoster = _settingsService.getUseSeasonPoster();
    _showHeroSection = _settingsService.getShowHeroSection();
    notifyListeners();
  }

  LibraryDensity get libraryDensity => _libraryDensity;
  bool get useSeasonPoster => _useSeasonPoster;
  bool get showHeroSection => _showHeroSection;

  Future<void> setLibraryDensity(LibraryDensity density) async {
    if (_libraryDensity != density) {
      _libraryDensity = density;
      await _settingsService.setLibraryDensity(density);
      notifyListeners();
    }
  }

  Future<void> setUseSeasonPoster(bool value) async {
    if (_useSeasonPoster != value) {
      _useSeasonPoster = value;
      await _settingsService.setUseSeasonPoster(value);
      notifyListeners();
    }
  }

  Future<void> setShowHeroSection(bool value) async {
    if (_showHeroSection != value) {
      _showHeroSection = value;
      await _settingsService.setShowHeroSection(value);
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
