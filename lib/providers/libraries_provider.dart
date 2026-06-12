import 'package:flutter/foundation.dart';

import '../media/media_library.dart';
import '../mixins/disposable_change_notifier_mixin.dart';
import '../services/data_aggregation_service.dart';
import '../services/storage_service.dart';
import '../utils/app_logger.dart';
import '../utils/content_utils.dart';
import 'multi_server_provider.dart';

/// Load state for the libraries provider
enum LibrariesLoadState { initial, loading, loaded, error }

/// Provider that serves as the single source of truth for library data.
/// Both SideNavigationRail and LibrariesScreen consume this provider
/// instead of independently fetching library data.
class LibrariesProvider extends ChangeNotifier with DisposableChangeNotifierMixin {
  LibrariesProvider({StorageService? storageService, MultiServerProvider? multiServer})
    : _storageService = storageService,
      _multiServer = multiServer {
    // Reload libraries when a new server comes online. Servers bind in waves
    // on sign-in / profile switch and slow ones reconnect after the initial
    // load; without this they stay missing from the sidebar until a re-switch
    // or restart. Removed in [dispose] so a profile switch can't leave a
    // stale listener on the app-global provider.
    _multiServer?.addOnlineServersListener(syncToOnlineServers);
  }

  final MultiServerProvider? _multiServer;
  StorageService? _storageService;
  DataAggregationService? _aggregationService;
  List<MediaLibrary> _libraries = [];
  LibrariesLoadState _loadState = LibrariesLoadState.initial;
  String? _errorMessage;

  /// Coalesces concurrent `loadLibraries()` calls so two simultaneous callers
  /// see the same in-flight result instead of racing two separate fetches.
  Future<void>? _inFlightLoad;

  /// Server ids whose library fetch *succeeded* in the current [_libraries], as
  /// reported by [DataAggregationService.getMediaLibrariesFromAllServers].
  /// Keyed on fetch success (not on which servers returned libraries) so a
  /// server that genuinely has zero libraries still counts as loaded, while a
  /// server whose fetch failed does not — the latter is retried on the next
  /// status emission instead of being cached as "loaded" forever. Drives
  /// [syncToOnlineServers].
  Set<String> _loadedServerIds = {};

  /// Set when a (re)load is requested while one is already in flight, so the
  /// loop runs another pass: a server that comes online *during* a load would
  /// otherwise be lost to the coalesced [_inFlightLoad].
  bool _hasPendingLoad = false;

  /// Newly-online servers queued for a delta pass — fetched and merged
  /// without refetching the already-loaded servers.
  final Set<String> _pendingDeltaServerIds = {};

  /// Unmodifiable list of all libraries (filtered for supported types, ordered)
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
    if (_aggregationService == null || onlineServerIds.isEmpty) return Future<void>.value();
    if (_loadState == LibrariesLoadState.loaded && _loadedServerIds.containsAll(onlineServerIds)) {
      return Future<void>.value();
    }
    // Nothing (or a failed pass) to merge into yet — run the full load.
    if (_loadState != LibrariesLoadState.loaded) return _load();
    _pendingDeltaServerIds.addAll(onlineServerIds.difference(_loadedServerIds));
    return _ensureLoadLoop();
  }

  /// Load libraries from all connected servers, unconditionally. Used by
  /// pull-to-refresh, inline connection-add, and library reordering.
  /// Filters out music libraries and applies saved ordering.
  Future<void> loadLibraries() => _load();

  /// Single entry point for every full (re)load. Concurrent callers coalesce
  /// onto one in-flight pass; a request that arrives mid-pass is replayed by
  /// [_runLoadLoop] so it isn't masked by that coalescing. Each pass fetches
  /// whatever is online at fetch time, so no caller needs to specify a target.
  Future<void> _load() {
    _hasPendingLoad = true;
    return _ensureLoadLoop();
  }

  Future<void> _ensureLoadLoop() => _inFlightLoad ??= _runLoadLoop().whenComplete(() => _inFlightLoad = null);

  Future<void> _runLoadLoop() async {
    while (_hasPendingLoad || _pendingDeltaServerIds.isNotEmpty) {
      if (_hasPendingLoad) {
        _hasPendingLoad = false;
        _pendingDeltaServerIds.clear(); // a full pass covers every server
        final succeeded = await _loadLibrariesInternal();
        // Stop on failure so a persistently failing fetch can't hot-loop; the
        // next server-status emission re-drives the sync.
        if (!succeeded) break;
      } else {
        final ids = Set<String>.of(_pendingDeltaServerIds);
        _pendingDeltaServerIds.clear();
        await _loadDelta(ids);
      }
    }
  }

  /// Fetch libraries from [serverIds] only (servers that came online after
  /// the last full pass) and merge them into the loaded list. Failures keep
  /// the current list and leave the ids un-loaded, so the next status
  /// emission retries them.
  Future<void> _loadDelta(Set<String> serverIds) async {
    // A full pass may have covered these ids while they sat in the queue.
    final ids = serverIds.difference(_loadedServerIds);
    if (ids.isEmpty) return;

    try {
      final result = await _aggregationService!.getMediaLibrariesFromAllServers(serverIds: ids);
      final fresh = result.libraries.where((lib) => !ContentTypeHelper.isMusicLibrary(lib)).toList();

      final merged = [
        for (final lib in _libraries)
          if (!ids.contains(lib.serverId)) lib,
        ...fresh,
      ];
      final storage = _storageService ??= await StorageService.getInstance();
      _libraries = _applyLibraryOrder(merged, storage.getLibraryOrder());
      // Union *succeeded* ids only, so a server whose fetch failed is retried
      // on the next status emission instead of being cached as loaded.
      _loadedServerIds = {..._loadedServerIds, ...result.succeededServerIds};

      appLogger.i('LibrariesProvider: merged ${fresh.length} libraries from $ids');
      safeNotifyListeners();
    } catch (e, stackTrace) {
      appLogger.e('LibrariesProvider: delta load failed for $ids', error: e, stackTrace: stackTrace);
    }
  }

  /// Returns `true` on a successful load, `false` on error.
  Future<bool> _loadLibrariesInternal() async {
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

      // Filter out music libraries (not supported)
      final filteredLibraries = result.libraries.where((lib) => !ContentTypeHelper.isMusicLibrary(lib)).toList();

      // Apply saved library order
      final storage = _storageService ??= await StorageService.getInstance();
      final savedOrder = storage.getLibraryOrder();
      final orderedLibraries = _applyLibraryOrder(filteredLibraries, savedOrder);

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
    if (_aggregationService == null) {
      appLogger.w('LibrariesProvider: Cannot refresh - not initialized');
      return;
    }
    await loadLibraries();
  }

  /// Update the library order and persist it.
  Future<void> updateLibraryOrder(List<MediaLibrary> orderedLibraries) async {
    _libraries = List.from(orderedLibraries);
    safeNotifyListeners();

    // Save the new order
    final storage = _storageService ??= await StorageService.getInstance();
    final libraryKeys = orderedLibraries.map((lib) => lib.globalKey).toList();
    await storage.saveLibraryOrder(libraryKeys);

    appLogger.d('LibrariesProvider: Updated library order');
  }

  /// Clear all library data (for profile switch or logout).
  void clear() {
    _libraries = [];
    _loadState = LibrariesLoadState.initial;
    _errorMessage = null;
    _loadedServerIds = {};
    _hasPendingLoad = false;
    _pendingDeltaServerIds.clear();
    safeNotifyListeners();
    appLogger.d('LibrariesProvider: Cleared library data');
  }

  @override
  void dispose() {
    _multiServer?.removeOnlineServersListener(syncToOnlineServers);
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
