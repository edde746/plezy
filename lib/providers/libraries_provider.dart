import 'package:flutter/foundation.dart';

import '../media/media_library.dart';
import '../mixins/disposable_change_notifier_mixin.dart';
import '../services/data_aggregation_service.dart';
import '../services/storage_service.dart';
import '../utils/app_logger.dart';
import '../utils/coalesced_load_coordinator.dart';
import 'multi_server_provider.dart';

/// Load state for the libraries provider
enum LibrariesLoadState { initial, loading, loaded, error }

/// Provider that serves as the single source of truth for library data.
/// Both SideNavigationRail and LibrariesScreen consume this provider
/// instead of independently fetching library data.
class LibrariesProvider extends ChangeNotifier with DisposableChangeNotifierMixin {
  LibrariesProvider({this._storageService, this._multiServer, bool Function()? isProfileBinding})
    : _isProfileBinding = isProfileBinding ?? _neverBinding {
    _loadCoordinator = CoalescedLoadCoordinator<String>(
      onFull: () async {
        await _loadLibrariesInternal();
      },
      onDelta: _loadDelta,
    );
    // Reload libraries when a new server comes online. Servers bind in waves
    // on sign-in / profile switch and slow ones reconnect after the initial
    // load; without this they stay missing from the sidebar until a re-switch
    // or restart. Removed in [dispose] so a profile switch can't leave a
    // stale listener on the app-global provider.
    _multiServer?.addOnlineServersListener(syncToOnlineServers);
  }

  static bool _neverBinding() => false;

  final MultiServerProvider? _multiServer;

  /// Whether the profile binder is still wiring servers — a zero-success
  /// first load during binding stays in the loading state instead of
  /// flashing "no libraries" (main_screen primes another load once binding
  /// settles).
  final bool Function() _isProfileBinding;

  StorageService? _storageService;
  DataAggregationService? _aggregationService;
  List<MediaLibrary> _libraries = [];
  LibrariesLoadState _loadState = LibrariesLoadState.initial;
  String? _errorMessage;

  late final CoalescedLoadCoordinator<String> _loadCoordinator;

  /// Server ids whose library fetch *succeeded* in the current [_libraries], as
  /// reported by [DataAggregationService.getMediaLibrariesFromAllServers].
  /// Keyed on fetch success (not on which servers returned libraries) so a
  /// server that genuinely has zero libraries still counts as loaded, while a
  /// server whose fetch failed does not — the latter is retried on the next
  /// status emission instead of being cached as "loaded" forever. Drives
  /// [syncToOnlineServers].
  Set<String> _loadedServerIds = {};

  /// Unmodifiable list of all libraries (ordered)
  List<MediaLibrary> get libraries => List.unmodifiable(_libraries);

  /// Whether libraries are currently being loaded
  bool get isLoading => _loadState == LibrariesLoadState.loading;

  /// Whether libraries have been loaded at least once
  bool get hasLoaded => _loadState == LibrariesLoadState.loaded;

  /// Current load state
  LibrariesLoadState get loadState => _loadState;

  /// Error message if loading failed
  String? get errorMessage => _errorMessage;

  /// Whether libraries are available
  bool get hasLibraries => _libraries.isNotEmpty;

  /// Initialize the provider with the aggregation service.
  /// This should be called after server connection is established.
  void initialize(DataAggregationService service) {
    if (isDisposed) return;
    _aggregationService = service;
  }

  /// Reload libraries when the set of online servers has grown since the last
  /// load. Servers connect in waves — the owner Plex account, then each
  /// borrowed/shared connection, then Jellyfin, plus slow servers that
  /// reconnect after timing out — and each wave must surface in the sidebar
  /// without a profile re-switch or app restart.
  ///
  /// No-op when uninitialized, when [onlineServerIds] is empty, or when every
  /// id is already represented in the current load. That last guard keeps the
  /// many unrelated reasons the server-status stream fires (visibility churn,
  /// auth errors, Live TV probes, a server going offline) from causing reload
  /// storms.
  ///
  /// Once a full pass has loaded, only the genuinely new servers are fetched
  /// and merged in; already-loaded servers are not refetched.
  Future<void> syncToOnlineServers(Set<String> onlineServerIds) {
    if (isDisposed || _aggregationService == null || onlineServerIds.isEmpty) return Future<void>.value();
    if (_loadState == LibrariesLoadState.loaded && _loadedServerIds.containsAll(onlineServerIds)) {
      return Future<void>.value();
    }
    // Nothing (or a failed pass) to merge into yet — run the full load.
    if (_loadState != LibrariesLoadState.loaded) return _load();
    return _loadCoordinator.requestDelta(onlineServerIds.difference(_loadedServerIds));
  }

  /// Load libraries from all connected servers, unconditionally. Used by
  /// pull-to-refresh, inline connection-add, and library reordering.
  /// Applies saved ordering.
  Future<void> loadLibraries() => _load();

  /// Single entry point for every full (re)load. Each pass fetches whatever is
  /// online at fetch time, so no caller needs to specify a target.
  Future<void> _load() {
    if (isDisposed) return Future<void>.value();
    return _loadCoordinator.requestFull();
  }

  /// Fetch libraries from [serverIds] only (servers that came online after
  /// the last full pass) and merge them into the loaded list. Failures keep
  /// the current list and leave the ids un-loaded, so the next status
  /// emission retries them.
  Future<void> _loadDelta(Set<String> serverIds) async {
    if (isDisposed) return;
    // A full pass may have covered these ids while they sat in the queue.
    final ids = serverIds.difference(_loadedServerIds);
    if (ids.isEmpty) return;

    try {
      final result = await _aggregationService!.getMediaLibrariesFromAllServers(serverIds: ids);
      if (isDisposed) return;
      final fresh = result.libraries;

      final merged = [
        for (final lib in _libraries)
          if (!ids.contains(lib.serverId)) lib,
        ...fresh,
      ];
      var storage = _storageService;
      if (storage == null) {
        storage = await StorageService.getInstance();
        if (isDisposed) return;
        _storageService = storage;
      }
      _libraries = _applyLibraryOrder(merged, storage.getLibraryOrder());
      // Union *succeeded* ids only, so a server whose fetch failed is retried
      // on the next status emission instead of being cached as loaded.
      _loadedServerIds = {..._loadedServerIds, ...result.succeededServerIds};

      appLogger.i('LibrariesProvider: merged ${fresh.length} libraries from $ids');
      safeNotifyListeners();
    } catch (e, stackTrace) {
      if (isDisposed) return;
      appLogger.e('LibrariesProvider: delta load failed for $ids', error: e, stackTrace: stackTrace);
    }
  }

  /// Returns `true` on a successful load, `false` on error.
  Future<bool> _loadLibrariesInternal() async {
    if (isDisposed) return false;
    if (_aggregationService == null) {
      appLogger.w('LibrariesProvider: Cannot load libraries - not initialized');
      return false;
    }

    // Reloading over an already-loaded list (a reactive server-connect sync, an
    // inline connection add, a reorder) must not flip the UI back to a loading
    // state: screens such as LibrariesScreen replace their whole body with a
    // spinner whenever `isLoading` is true. Keep the current list visible and
    // swap in the fuller one when the fetch completes; only the first load (or
    // a reload after clear()/error) surfaces the spinner.
    final reloadInPlace = _loadState == LibrariesLoadState.loaded;
    if (!reloadInPlace) {
      _loadState = LibrariesLoadState.loading;
      _errorMessage = null;
      safeNotifyListeners();
    }

    try {
      // Fetch libraries from every connected backend (Plex + Jellyfin).
      // The aggregation service converts Plex-typed responses to MediaLibrary
      // internally; Jellyfin clients return MediaLibrary natively.
      final result = await _aggregationService!.getMediaLibrariesFromAllServers();
      if (isDisposed) return false;

      // A pass in which zero servers succeeded is never authoritative — it
      // must not replace existing data, and it may only commit "loaded,
      // empty" when the failure is settled (not a client-side abort, not
      // mid-binding). Recovery is guaranteed: the binding-settle prime and
      // the next status emission both re-drive a load while state isn't a
      // fully-covered `loaded`.
      if (result.succeededServerIds.isEmpty) {
        if (reloadInPlace) {
          // A totally-failed silent refresh keeps the last good list instead
          // of wiping the sidebar. Clear the succeeded set so the next
          // status emission refetches rather than treating the stale list as
          // covering those servers.
          appLogger.w('LibrariesProvider: refresh failed on all servers; keeping previous libraries');
          _loadedServerIds = result.succeededServerIds;
          return false;
        }
        if (result.cancelledServerIds.isNotEmpty || _isProfileBinding()) {
          appLogger.d('LibrariesProvider: first load disrupted (zero successful servers); staying in loading state');
          return false;
        }
      }

      // Apply saved library order
      var storage = _storageService;
      if (storage == null) {
        storage = await StorageService.getInstance();
        if (isDisposed) return false;
        _storageService = storage;
      }
      final savedOrder = storage.getLibraryOrder();
      final orderedLibraries = _applyLibraryOrder(result.libraries, savedOrder);

      _libraries = orderedLibraries;
      // Track which servers actually responded so [syncToOnlineServers] can tell
      // a genuinely new server from one already covered. Keyed on fetch success
      // (not on which servers returned libraries) so a zero-library server still
      // counts as loaded, while a server whose fetch failed is left out and
      // retried on the next status emission.
      _loadedServerIds = result.succeededServerIds;
      _loadState = LibrariesLoadState.loaded;
      _errorMessage = null;

      appLogger.i('LibrariesProvider: Loaded ${_libraries.length} libraries');
      safeNotifyListeners();
      return true;
    } catch (e, stackTrace) {
      if (isDisposed) return false;
      appLogger.e('LibrariesProvider: Failed to load libraries', error: e, stackTrace: stackTrace);
      // A refresh that fails over an existing list keeps the last good data and
      // `loaded` state instead of blanking to an error screen; the next status
      // emission re-drives the sync.
      if (reloadInPlace) return false;
      _loadState = LibrariesLoadState.error;
      _errorMessage = e.toString();
      safeNotifyListeners();
      return false;
    }
  }

  /// Refresh libraries by reloading from the connected servers.
  Future<void> refresh() async {
    if (isDisposed) return;
    if (_aggregationService == null) {
      appLogger.w('LibrariesProvider: Cannot refresh - not initialized');
      return;
    }
    await loadLibraries();
  }

  /// Update the library order and persist it.
  Future<void> updateLibraryOrder(List<MediaLibrary> orderedLibraries) async {
    if (isDisposed) return;
    _libraries = List.from(orderedLibraries);
    safeNotifyListeners();

    // Save the new order
    var storage = _storageService;
    if (storage == null) {
      storage = await StorageService.getInstance();
      if (isDisposed) return;
      _storageService = storage;
    }
    if (isDisposed) return;
    final libraryKeys = orderedLibraries.map((lib) => lib.globalKey).toList();
    await storage.saveLibraryOrder(libraryKeys);

    if (isDisposed) return;
    appLogger.d('LibrariesProvider: Updated library order');
  }

  /// Clear all library data (for profile switch or logout).
  void clear() {
    if (isDisposed) return;
    _libraries = [];
    _loadState = LibrariesLoadState.initial;
    _errorMessage = null;
    _loadedServerIds = {};
    _loadCoordinator.clearPending();
    safeNotifyListeners();
    appLogger.d('LibrariesProvider: Cleared library data');
  }

  @override
  void dispose() {
    _multiServer?.removeOnlineServersListener(syncToOnlineServers);
    _loadCoordinator.dispose();
    super.dispose();
  }

  /// Apply saved library order to a list of libraries.
  List<MediaLibrary> _applyLibraryOrder(List<MediaLibrary> libraries, List<String>? savedOrder) {
    if (savedOrder == null || savedOrder.isEmpty) {
      return libraries;
    }

    // Create a map for quick lookup
    final libraryMap = {for (final lib in libraries) lib.globalKey: lib};

    // Build ordered list based on saved order
    final orderedLibraries = <MediaLibrary>[];
    for (final key in savedOrder) {
      final lib = libraryMap.remove(key);
      if (lib != null) {
        orderedLibraries.add(lib);
      }
    }

    // Add any new libraries that weren't in the saved order
    orderedLibraries.addAll(libraryMap.values);

    return orderedLibraries;
  }
}
