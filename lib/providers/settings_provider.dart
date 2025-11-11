import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  late SettingsService _settingsService;
  LibraryDensity _libraryDensity = LibraryDensity.normal;
  ViewMode _viewMode = ViewMode.grid;
  bool _useSeasonPoster = false;
  bool _showHeroSection = true;
  bool _shuffleUnwatchedOnly = true;
  bool _shuffleOrderNavigation = true;
  bool _shuffleLoopQueue = false;

  SettingsProvider() {
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    _settingsService = await SettingsService.getInstance();
    _libraryDensity = _settingsService.getLibraryDensity();
    _viewMode = _settingsService.getViewMode();
    _useSeasonPoster = _settingsService.getUseSeasonPoster();
    _showHeroSection = _settingsService.getShowHeroSection();
    _shuffleUnwatchedOnly = _settingsService.getShuffleUnwatchedOnly();
    _shuffleOrderNavigation = _settingsService.getShuffleOrderNavigation();
    _shuffleLoopQueue = _settingsService.getShuffleLoopQueue();
    notifyListeners();
  }

  LibraryDensity get libraryDensity => _libraryDensity;
  ViewMode get viewMode => _viewMode;
  bool get useSeasonPoster => _useSeasonPoster;
  bool get showHeroSection => _showHeroSection;
  bool get shuffleUnwatchedOnly => _shuffleUnwatchedOnly;
  bool get shuffleOrderNavigation => _shuffleOrderNavigation;
  bool get shuffleLoopQueue => _shuffleLoopQueue;

  Future<void> setLibraryDensity(LibraryDensity density) async {
    if (_libraryDensity != density) {
      _libraryDensity = density;
      await _settingsService.setLibraryDensity(density);
      notifyListeners();
    }
  }

  Future<void> setViewMode(ViewMode mode) async {
    if (_viewMode != mode) {
      _viewMode = mode;
      await _settingsService.setViewMode(mode);
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

  Future<void> setShuffleUnwatchedOnly(bool value) async {
    if (_shuffleUnwatchedOnly != value) {
      _shuffleUnwatchedOnly = value;
      await _settingsService.setShuffleUnwatchedOnly(value);
      notifyListeners();
    }
  }

  Future<void> setShuffleOrderNavigation(bool value) async {
    if (_shuffleOrderNavigation != value) {
      _shuffleOrderNavigation = value;
      await _settingsService.setShuffleOrderNavigation(value);
      notifyListeners();
    }
  }

  Future<void> setShuffleLoopQueue(bool value) async {
    if (_shuffleLoopQueue != value) {
      _shuffleLoopQueue = value;
      await _settingsService.setShuffleLoopQueue(value);
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
