import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

/// Provider for managing hidden library state across the app.
/// This ensures that when a library is hidden/unhidden in one screen,
/// all other screens are automatically updated.
class HiddenLibrariesProvider extends ChangeNotifier {
  late StorageService _storageService;
  Set<String> _hiddenLibraryKeys = {};
  bool _isInitialized = false;

  /// Get an unmodifiable copy of hidden library keys
  Set<String> get hiddenLibraryKeys => Set.unmodifiable(_hiddenLibraryKeys);

  /// Check if the provider has completed initialization
  bool get isInitialized => _isInitialized;

  HiddenLibrariesProvider() {
    _initialize();
  }

  /// Initialize the provider by loading hidden libraries from storage
  Future<void> _initialize() async {
    _storageService = await StorageService.getInstance();
    _hiddenLibraryKeys = _storageService.getHiddenLibraries();
    _isInitialized = true;
    notifyListeners();
  }

  /// Hide a library by its key
  /// Updates both in-memory state and persistent storage
  Future<void> hideLibrary(String libraryKey) async {
    if (!_hiddenLibraryKeys.contains(libraryKey)) {
      _hiddenLibraryKeys = Set.from(_hiddenLibraryKeys)..add(libraryKey);
      await _storageService.saveHiddenLibraries(_hiddenLibraryKeys);
      notifyListeners();
    }
  }

  /// Unhide a library by its key
  /// Updates both in-memory state and persistent storage
  Future<void> unhideLibrary(String libraryKey) async {
    if (_hiddenLibraryKeys.contains(libraryKey)) {
      _hiddenLibraryKeys = Set.from(_hiddenLibraryKeys)..remove(libraryKey);
      await _storageService.saveHiddenLibraries(_hiddenLibraryKeys);
      notifyListeners();
    }
  }

  /// Check if a specific library is hidden
  bool isLibraryHidden(String libraryKey) {
    return _hiddenLibraryKeys.contains(libraryKey);
  }

  /// Refresh hidden libraries from storage
  /// Useful if storage was modified outside the provider
  Future<void> refresh() async {
    _hiddenLibraryKeys = _storageService.getHiddenLibraries();
    notifyListeners();
  }
}
