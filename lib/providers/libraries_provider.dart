import 'package:flutter/foundation.dart';

import '../models/plex_library.dart';
import '../services/data_aggregation_service.dart';
import '../services/storage_service.dart';
import '../utils/app_logger.dart';
import '../utils/content_utils.dart';

/// Load state for the libraries provider
enum LibrariesLoadState { initial, loading, loaded, error }

/// Provider that serves as the single source of truth for library data.
/// Both SideNavigationRail and LibrariesScreen consume this provider
/// instead of independently fetching library data.
class LibrariesProvider extends ChangeNotifier {
  DataAggregationService? _aggregationService;
  List<PlexLibrary> _libraries = [];
  LibrariesLoadState _loadState = LibrariesLoadState.initial;
  String? _errorMessage;

  /// Unmodifiable list of all libraries (filtered for supported types, ordered)
  List<PlexLibrary> get libraries => List.unmodifiable(_libraries);

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

  /// Load libraries from all connected servers.
  /// Filters out music libraries and applies saved ordering.
  Future<void> loadLibraries() async {
    if (_aggregationService == null) {
      appLogger.w('LibrariesProvider: Cannot load libraries - not initialized');
      return;
    }

    _loadState = LibrariesLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch libraries from all servers
      final allLibraries = await _aggregationService!.getLibrariesFromAllServers();

      // Filter out music libraries (not supported)
      final filteredLibraries = allLibraries.where((lib) => !ContentTypeHelper.isMusicLibrary(lib)).toList();

      // Apply saved library order
      final storage = await StorageService.getInstance();
      final savedOrder = storage.getLibraryOrder();
      final orderedLibraries = _applyLibraryOrder(filteredLibraries, savedOrder);

      _libraries = orderedLibraries;
      _loadState = LibrariesLoadState.loaded;
      _errorMessage = null;

      appLogger.i('LibrariesProvider: Loaded ${_libraries.length} libraries');
      notifyListeners();
    } catch (e, stackTrace) {
      appLogger.e('LibrariesProvider: Failed to load libraries', error: e, stackTrace: stackTrace);
      _loadState = LibrariesLoadState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Refresh libraries by clearing cache and reloading.
  Future<void> refresh() async {
    if (_aggregationService == null) {
      appLogger.w('LibrariesProvider: Cannot refresh - not initialized');
      return;
    }

    // Clear aggregation service cache
    _aggregationService!.clearCache();

    // Reload libraries
    await loadLibraries();
  }

  /// Update the library order and persist it.
  Future<void> updateLibraryOrder(List<PlexLibrary> orderedLibraries) async {
    _libraries = List.from(orderedLibraries);
    notifyListeners();

    // Save the new order
    final storage = await StorageService.getInstance();
    final libraryKeys = orderedLibraries.map((lib) => lib.globalKey).toList();
    await storage.saveLibraryOrder(libraryKeys);

    appLogger.d('LibrariesProvider: Updated library order');
  }

  /// Clear all library data (for profile switch or logout).
  void clear() {
    _libraries = [];
    _loadState = LibrariesLoadState.initial;
    _errorMessage = null;
    notifyListeners();
    appLogger.d('LibrariesProvider: Cleared library data');
  }

  /// Apply saved library order to a list of libraries.
  List<PlexLibrary> _applyLibraryOrder(List<PlexLibrary> libraries, List<String>? savedOrder) {
    if (savedOrder == null || savedOrder.isEmpty) {
      return libraries;
    }

    // Create a map for quick lookup
    final libraryMap = {for (var lib in libraries) lib.globalKey: lib};

    // Build ordered list based on saved order
    final orderedLibraries = <PlexLibrary>[];
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
