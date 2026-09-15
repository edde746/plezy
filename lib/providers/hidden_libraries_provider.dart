import 'package:flutter/foundation.dart';
import '../mixins/disposable_change_notifier_mixin.dart';
import '../services/storage_service.dart';

/// Provider for managing hidden library state across the app.
/// This ensures that when a library is hidden/unhidden in one screen,
/// all other screens are automatically updated.
class HiddenLibrariesProvider extends ChangeNotifier with DisposableChangeNotifierMixin {
  StorageService? _storageService;
  final String? profileId;
  Set<String> _hiddenLibraryKeys = {};
  bool _isInitialized = false;
  late final Future<void> _initFuture;

  HiddenLibrariesProvider({this._storageService, this.profileId}) {
    // Start initialization eagerly to reduce race conditions
    _initFuture = _initialize();
  }

  /// Ensures the provider is initialized. Call this before accessing hidden
  /// libraries in contexts where you need the actual persisted values.
  Future<void> ensureInitialized() => _initFuture;

  /// Check if the provider has completed initialization
  bool get isInitialized => _isInitialized;

  /// Get an unmodifiable copy of hidden library keys
  Set<String> get hiddenLibraryKeys => Set.unmodifiable(_hiddenLibraryKeys);

  /// Initialize the provider by loading hidden libraries from storage
  Future<void> _initialize() async {
    await _loadFromStorage();
    _isInitialized = true;
    safeNotifyListeners();
  }

  Future<void> _loadFromStorage() async {
    final storage = _storageService ??= await StorageService.getInstance();
    final scopedProfileId = profileId;
    _hiddenLibraryKeys = scopedProfileId == null
        ? storage.getHiddenLibraries()
        : storage.getHiddenLibrariesForProfile(scopedProfileId);
  }

  /// Hide a library by its key
  /// Updates both in-memory state and persistent storage
  Future<void> hideLibrary(String libraryKey, {void Function()? checkCurrent}) =>
      setLibraryHidden(libraryKey, true, checkCurrent: checkCurrent);

  /// Unhide a library by its key.
  Future<void> unhideLibrary(String libraryKey, {void Function()? checkCurrent}) =>
      setLibraryHidden(libraryKey, false, checkCurrent: checkCurrent);

  Future<void> setLibraryHidden(String libraryKey, bool hidden, {void Function()? checkCurrent}) async {
    await ensureInitialized();
    if (isDisposed) return;
    checkCurrent?.call();
    if (_hiddenLibraryKeys.contains(libraryKey) == hidden) return;
    final next = Set<String>.of(_hiddenLibraryKeys);
    hidden ? next.add(libraryKey) : next.remove(libraryKey);
    final storage = _storageService!;
    final scopedProfileId = profileId;
    if (scopedProfileId == null) {
      await storage.saveHiddenLibraries(next);
    } else {
      await storage.saveHiddenLibrariesForProfile(scopedProfileId, next);
    }
    if (isDisposed) return;
    checkCurrent?.call();
    _hiddenLibraryKeys = next;
    safeNotifyListeners();
  }

  /// Check if a specific library is hidden
  @visibleForTesting
  bool isLibraryHidden(String libraryKey) => _hiddenLibraryKeys.contains(libraryKey);

  /// Refresh hidden libraries from storage
  /// Useful if storage was modified outside the provider
  Future<void> refresh() async {
    await _loadFromStorage();
    _isInitialized = true;
    safeNotifyListeners();
  }
}
