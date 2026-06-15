import 'dart:async';

import 'package:flutter/foundation.dart';

import '../media/ids.dart';
import '../media/media_hub.dart';
import '../media/media_item.dart';
import '../media/media_server_client.dart';
import '../mixins/disposable_change_notifier_mixin.dart';
import '../mixins/event_aware.dart';
import '../services/settings_service.dart';
import '../services/data_aggregation_service.dart';
import '../services/system_shelf_service.dart';
import '../utils/app_logger.dart';
import '../utils/global_key_utils.dart';
import '../utils/media_hub_ordering.dart';
import '../utils/watch_state_notifier.dart';
import 'hidden_libraries_provider.dart';
import 'libraries_provider.dart';
import 'multi_server_provider.dart';

enum DiscoverLoadState { initial, loading, loaded, error }

/// Owns the Discover tab's data: the Continue Watching row and the home hub
/// list, including the refresh policy that used to live in the screen —
/// watch events refresh only Continue Watching (one on-deck call, zero hub
/// refetches), hidden-library changes trigger a full reload, library-order
/// changes re-sort hubs in place without refetching, and the platform
/// launcher shelf syncs from every on-deck update.
///
/// Lives inside the profile-keyed provider subtree, so a profile switch
/// resets it by construction. The screen is a consumer: it renders this
/// state and keeps only UI concerns (hero carousel, focus, spotlight).
class DiscoverProvider extends ChangeNotifier with DisposableChangeNotifierMixin {
  /// Preview row caps at 20; one extra item is fetched as a probe so
  /// [hasMoreContinueWatching] can show the "more" affordance without a
  /// second request.
  static const int continueWatchingPreviewLimit = 20;
  static const int _continueWatchingProbeLimit = continueWatchingPreviewLimit + 1;

  DiscoverProvider(this._multiServer, this._hiddenLibraries, this._libraries, {required this.isProfileBinding}) {
    // Late server connects (reconnect after outage, slow wave) refresh
    // discover the same way they refresh libraries. Removed in [dispose] so a
    // profile switch can't leave a stale listener on the app-global provider.
    _multiServer.addOnlineServersListener(syncToOnlineServers);
    _hiddenLibraries.addListener(_onHiddenLibrariesChanged);
    _lastSeenLibraryOrderKeys = _libraryOrderKeys();
    _libraries.addListener(_onLibrariesChanged);
    _watchStateSubscription = subscribeToHierarchicalEvents<WatchStateEvent>(
      notifier: WatchStateNotifier(),
      mounted: () => !isDisposed,
      serverId: () => null,
      globalKeys: () => _watchedGlobalKeys,
      itemIds: () => _watchedIds,
      onEvent: _onWatchStateChanged,
    );
  }

  final MultiServerProvider _multiServer;
  final HiddenLibrariesProvider _hiddenLibraries;
  final LibrariesProvider _libraries;

  /// Whether the profile binder is still wiring servers — a no-servers load
  /// during binding stays in the loading state instead of flashing an error
  /// (main_screen primes another load once binding settles).
  final bool Function() isProfileBinding;

  StreamSubscription<WatchStateEvent>? _watchStateSubscription;

  List<MediaItem> _onDeck = [];
  List<MediaHub> _hubs = [];
  bool _hasMoreContinueWatching = false;
  DiscoverLoadState _onDeckState = DiscoverLoadState.initial;
  DiscoverLoadState _hubsState = DiscoverLoadState.initial;
  String? _errorMessage;
  int _loadGeneration = 0;

  Set<String> _lastSeenHiddenKeys = {};
  List<String> _lastSeenLibraryOrderKeys = const [];

  /// Online servers whose Continue Watching fetch succeeded in the current
  /// on-deck list. Tracked separately from hubs so a transient failure in one
  /// surface does not cache the other as loaded forever or force unnecessary
  /// refetches.
  Set<String> _loadedOnDeckServerIds = {};

  /// Online servers whose home-hub fetch succeeded in the current hub list.
  Set<String> _loadedHubServerIds = {};

  Set<String> get _fullyLoadedServerIds => _loadedOnDeckServerIds.intersection(_loadedHubServerIds);

  Future<void>? _inFlightLoad;
  bool _hasPendingLoad = false;

  /// Newly-online servers queued for a delta pass — fetched and merged
  /// without repeating the full multi-server fan-out.
  final Set<String> _pendingDeltaServerIds = {};

  Future<void>? _systemShelfSyncFuture;
  List<MediaItem>? _pendingSystemShelfItems;

  List<MediaItem> get onDeck => _onDeck;
  List<MediaHub> get hubs => _hubs;
  bool get hasMoreContinueWatching => _hasMoreContinueWatching;

  /// Raw load failure (unlocalized); the screen wraps it for display.
  String? get errorMessage => _errorMessage;

  /// True until the first on-deck result (or error) of a [load] pass lands.
  bool get isLoading => _onDeckState == DiscoverLoadState.initial || _onDeckState == DiscoverLoadState.loading;

  bool get areHubsLoading => _hubsState == DiscoverLoadState.initial || _hubsState == DiscoverLoadState.loading;

  /// Bumped each time a [load] pass replaces the on-deck list. The screen
  /// uses this to distinguish "full reload — reset the hero carousel" from
  /// a background Continue Watching refresh (clamp only).
  int get loadGeneration => _loadGeneration;

  /// Refresh when a server comes online *mid-session* (reconnect, late wave) —
  /// its hubs and continue-watching rows are otherwise missing until a manual
  /// refresh. During profile binding this is a no-op: servers bind in waves
  /// and main_screen primes one [load] when binding settles, so reacting to
  /// each wave would multiply the (expensive) hub fan-out at startup.
  ///
  /// Once a full pass has loaded, only the genuinely new servers are fetched
  /// and merged in; already-loaded servers are not refetched.
  Future<void> syncToOnlineServers(Set<String> onlineServerIds) {
    if (onlineServerIds.isEmpty || isProfileBinding()) return Future<void>.value();
    if (
      _onDeckState == DiscoverLoadState.loaded &&
      _hubsState == DiscoverLoadState.loaded &&
      _fullyLoadedServerIds.containsAll(onlineServerIds)
    ) {
      return Future<void>.value();
    }
    // Nothing (or a failed pass) to merge into yet — run the full load.
    if (_onDeckState != DiscoverLoadState.loaded || _hubsState != DiscoverLoadState.loaded) return load();
    _pendingDeltaServerIds.addAll(onlineServerIds.difference(_fullyLoadedServerIds));
    return _ensureLoadLoop();
  }

  /// Full load of Continue Watching + hubs. Concurrent calls coalesce into
  /// the in-flight pass plus at most one trailing pass (so a request that
  /// arrives mid-load still observes its own fresh fetch).
  Future<void> load() {
    _hasPendingLoad = true;
    return _ensureLoadLoop();
  }

  Future<void> _ensureLoadLoop() => _inFlightLoad ??= _runLoadLoop().whenComplete(() => _inFlightLoad = null);

  Future<void> _runLoadLoop() async {
    while ((_hasPendingLoad || _pendingDeltaServerIds.isNotEmpty) && !isDisposed) {
      if (_hasPendingLoad) {
        _hasPendingLoad = false;
        _pendingDeltaServerIds.clear(); // a full pass covers every server
        await _loadOnce();
      } else {
        final ids = Set<String>.of(_pendingDeltaServerIds);
        _pendingDeltaServerIds.clear();
        await _loadDeltaOnce(ids);
      }
    }
  }

  Future<void> _loadOnce() async {
    // Yield to the microtask queue before the first notify so a load()
    // kicked off during build (the screen's initState) doesn't mark
    // listening widgets dirty mid-build.
    await null;
    appLogger.d('DiscoverProvider: loading content from all servers');
    _onDeckState = DiscoverLoadState.loading;
    _hubsState = DiscoverLoadState.loading;
    _errorMessage = null;
    safeNotifyListeners();

    try {
      if (!_multiServer.hasConnectedServers) {
        if (isProfileBinding()) return;
        throw Exception('No servers available');
      }

      await _hiddenLibraries.ensureInitialized();
      if (isDisposed) return;
      _lastSeenHiddenKeys = Set.of(_hiddenLibraries.hiddenLibraryKeys);

      final settings = await SettingsService.getInstance();
      final useGlobalHubs = settings.read(SettingsService.useGlobalHubs);
      final aggregation = _multiServer.aggregationService;

      // On-deck and hubs fetch in parallel; on-deck is published as soon as
      // it lands so the hero renders while hubs are still loading.
      final onDeckFuture = aggregation.getOnDeckFromAllServers(
        limit: _continueWatchingProbeLimit,
        hiddenLibraryKeys: _hiddenLibraries.hiddenLibraryKeys,
      );
      final hubsFuture = aggregation.getHubsFromAllServers(
        hiddenLibraryKeys: _hiddenLibraries.hiddenLibraryKeys,
        useGlobalHubs: useGlobalHubs,
        includePlaybackHubs: false,
      );

      final fetchedOnDeck = await onDeckFuture;
      if (isDisposed) return;
      _applyOnDeck(fetchedOnDeck.items);
      _onDeckState = DiscoverLoadState.loaded;
      _loadedOnDeckServerIds = fetchedOnDeck.succeededServerIds;
      _loadGeneration++;
      safeNotifyListeners();
      unawaited(_syncSystemShelf(_onDeck));

      final fetchedHubs = await hubsFuture;
      if (isDisposed) return;

      final filteredHubs = _filterDiscoverHubs(fetchedHubs.hubs);
      sortMediaHubsByLibraryOrder(filteredHubs, _libraries.libraries);

      appLogger.d('DiscoverProvider: ${_onDeck.length} on-deck items, ${filteredHubs.length} hubs');
      _hubs = filteredHubs;
      _hubsState = DiscoverLoadState.loaded;
      _loadedHubServerIds = fetchedHubs.succeededServerIds;
      safeNotifyListeners();
    } catch (e) {
      appLogger.e('Failed to load discover content', error: e);
      if (isDisposed) return;
      _errorMessage = e.toString();
      _onDeckState = DiscoverLoadState.error;
      _hubsState = DiscoverLoadState.error;
      safeNotifyListeners();
    }
  }

  /// Fetch Continue Watching + hubs from [serverIds] only (servers that came
  /// online after the last full pass) and merge them into the loaded state.
  /// Failures keep the loaded state and leave the ids un-loaded, so the next
  /// status emission retries them.
  Future<void> _loadDeltaOnce(Set<String> serverIds) async {
    // A full pass may have covered these ids while they sat in the queue.
    final ids = serverIds.difference(_fullyLoadedServerIds);
    final onDeckIds = ids.difference(_loadedOnDeckServerIds);
    final hubIds = ids.difference(_loadedHubServerIds);
    if (onDeckIds.isEmpty && hubIds.isEmpty) return;
    appLogger.d('DiscoverProvider: merging content from newly-online servers $ids (onDeck=$onDeckIds, hubs=$hubIds)');

    try {
      await _hiddenLibraries.ensureInitialized();
      if (isDisposed) return;

      final settings = await SettingsService.getInstance();
      final useGlobalHubs = settings.read(SettingsService.useGlobalHubs);
      final aggregation = _multiServer.aggregationService;

      final Future<OnDeckAggregationResult?> onDeckFuture = onDeckIds.isEmpty
          ? Future<OnDeckAggregationResult?>.value()
          : aggregation.getOnDeckFromAllServers(
              limit: _continueWatchingProbeLimit,
              hiddenLibraryKeys: _hiddenLibraries.hiddenLibraryKeys,
              serverIds: onDeckIds,
            );
      final Future<HubAggregationResult?> hubsFuture = hubIds.isEmpty
          ? Future<HubAggregationResult?>.value()
          : aggregation.getHubsFromAllServers(
              hiddenLibraryKeys: _hiddenLibraries.hiddenLibraryKeys,
              useGlobalHubs: useGlobalHubs,
              includePlaybackHubs: false,
              serverIds: hubIds,
            );

      final freshOnDeck = await onDeckFuture;
      final freshHubs = await hubsFuture;
      if (isDisposed) return;

      if (freshOnDeck != null) {
        final hadMore = _hasMoreContinueWatching;
        final mergedOnDeck = await aggregation.mergeContinueWatching(
          _onDeck,
          freshOnDeck.items,
          limit: _continueWatchingProbeLimit,
        );
        if (isDisposed) return;
        _applyOnDeck(mergedOnDeck);
        // The stored list is already trimmed, so the merge can't see old items
        // past the cap — a previously-true "more" affordance stays true.
        if (hadMore) _hasMoreContinueWatching = true;
        _loadedOnDeckServerIds = {..._loadedOnDeckServerIds, ...freshOnDeck.succeededServerIds};
        // No _loadGeneration bump: a delta behaves like the background Continue
        // Watching refresh (the hero clamps instead of resetting).
      }

      if (freshHubs != null) {
        final succeededHubIds = freshHubs.succeededServerIds;
        final mergedHubs = [
          ..._hubs.where((hub) => hub.serverId == null || !succeededHubIds.contains(hub.serverId)),
          ..._filterDiscoverHubs(freshHubs.hubs),
        ];
        sortMediaHubsByLibraryOrder(mergedHubs, _libraries.libraries);
        _hubs = mergedHubs;
        _loadedHubServerIds = {..._loadedHubServerIds, ...succeededHubIds};
      }

      appLogger.d('DiscoverProvider: ${_onDeck.length} on-deck items, ${_hubs.length} hubs after merging $ids');
      safeNotifyListeners();
      unawaited(_syncSystemShelf(_onDeck));
    } catch (e) {
      // Keep the loaded state — stale rows beat an error flash.
      appLogger.w('DiscoverProvider: delta load failed for $ids', error: e);
    }
  }

  /// Playback-progress hubs duplicate the top Continue Watching row.
  List<MediaHub> _filterDiscoverHubs(List<MediaHub> hubs) {
    return hubs.where((hub) {
      final hubId = hub.identifier?.toLowerCase() ?? '';
      final title = hub.title.toLowerCase();
      return !hubId.contains('ondeck') &&
          !hubId.contains('continue') &&
          !hubId.contains('nextup') &&
          !title.contains('continue watching') &&
          !title.contains('on deck') &&
          !title.contains('next up');
    }).toList();
  }

  /// Background refresh of Continue Watching only — never flips load states
  /// or surfaces errors (a stale row beats an error flash), never refetches
  /// hubs.
  Future<void> refreshContinueWatching() async {
    try {
      if (!_multiServer.hasConnectedServers) return;
      final fetched = await _multiServer.aggregationService.getOnDeckFromAllServers(
        limit: _continueWatchingProbeLimit,
        hiddenLibraryKeys: _hiddenLibraries.hiddenLibraryKeys,
      );
      if (isDisposed) return;
      _applyOnDeck(fetched.items);
      _loadedOnDeckServerIds = fetched.succeededServerIds;
      safeNotifyListeners();
      unawaited(_syncSystemShelf(_onDeck));
    } catch (e) {
      appLogger.w('Failed to refresh Continue Watching', error: e);
    }
  }

  /// The full unlimited Continue Watching list for the hub's load-more path.
  Future<List<MediaItem>> loadAllContinueWatching() async {
    if (!_multiServer.hasConnectedServers) return const [];
    await _hiddenLibraries.ensureInitialized();
    if (isDisposed) return const [];
    final fetched = await _multiServer.aggregationService.getOnDeckFromAllServers(
      hiddenLibraryKeys: _hiddenLibraries.hiddenLibraryKeys,
    );
    return fetched.items;
  }

  /// Refetch a single item (post-edit refresh from a hub row) and swap it
  /// into whichever lists contain it. Items can come from any registered
  /// server, so the owning server is resolved by scanning the visible lists.
  Future<void> updateItem(String itemId) async {
    try {
      final serverId = _serverIdForItem(itemId);
      if (serverId == null) return;
      final updated = await _multiServer.getClientForServer(ServerId(serverId))?.fetchItem(itemId);
      if (updated == null || isDisposed) return;
      _updateItemInLists(itemId, updated);
      safeNotifyListeners();
    } catch (_) {
      // Silently fail — the item will refresh on the next full reload.
    }
  }

  String? _serverIdForItem(String itemId) {
    for (final item in _onDeck) {
      if (item.id == itemId) return item.serverId;
    }
    for (final hub in _hubs) {
      for (final item in hub.items) {
        if (item.id == itemId) return item.serverId;
      }
    }
    return null;
  }

  void _updateItemInLists(String itemId, MediaItem updatedItem) {
    final onDeckIndex = _onDeck.indexWhere((item) => item.id == itemId);
    if (onDeckIndex != -1) {
      _onDeck = List.of(_onDeck)..[onDeckIndex] = updatedItem;
    }

    for (var i = 0; i < _hubs.length; i++) {
      final hub = _hubs[i];
      final itemIndex = hub.items.indexWhere((item) => item.id == itemId);
      if (itemIndex != -1) {
        final newItems = List<MediaItem>.from(hub.items);
        newItems[itemIndex] = updatedItem;
        _hubs = List.of(_hubs)..[i] = hub.copyWith(items: newItems);
      }
    }
  }

  void _applyOnDeck(List<MediaItem> fetched) {
    final hasMore = fetched.length > continueWatchingPreviewLimit;
    _onDeck = hasMore ? fetched.take(continueWatchingPreviewLimit).toList() : fetched;
    _hasMoreContinueWatching = hasMore;
  }

  // --- Event reactions -----------------------------------------------------

  /// Watch on-deck items and their parent shows/seasons (an episode's watch
  /// flip changes what Continue Watching should show for its series).
  Set<String>? get _watchedIds {
    final keys = <String>{};
    for (final item in _onDeck) {
      keys.add(item.id);
      if (item.parentId != null) keys.add(item.parentId!);
      if (item.grandparentId != null) keys.add(item.grandparentId!);
    }
    return keys;
  }

  Set<String>? get _watchedGlobalKeys {
    final keys = <String>{};
    for (final item in _onDeck) {
      final serverId = item.serverId;
      if (serverId == null) return null;

      keys.add(buildGlobalKey(ServerId(serverId), item.id));
      if (item.parentId != null) keys.add(buildGlobalKey(ServerId(serverId), item.parentId!));
      if (item.grandparentId != null) keys.add(buildGlobalKey(ServerId(serverId), item.grandparentId!));
    }
    return keys;
  }

  void _onWatchStateChanged(WatchStateEvent event) {
    if (event.changeType == WatchStateChangeType.removedFromContinueWatching) {
      final remaining = _onDeck.where((item) => item.id != event.itemId).toList();
      if (remaining.length != _onDeck.length) {
        _onDeck = remaining;
        safeNotifyListeners();
      }
    }
    unawaited(refreshContinueWatching());
  }

  void _onHiddenLibrariesChanged() {
    final currentKeys = _hiddenLibraries.hiddenLibraryKeys;
    if (currentKeys.length == _lastSeenHiddenKeys.length && currentKeys.containsAll(_lastSeenHiddenKeys)) {
      return;
    }
    _lastSeenHiddenKeys = Set.of(currentKeys);
    unawaited(load());
  }

  void _onLibrariesChanged() {
    final currentKeys = _libraryOrderKeys();
    if (listEquals(currentKeys, _lastSeenLibraryOrderKeys)) return;
    _lastSeenLibraryOrderKeys = currentKeys;
    if (_hubs.isEmpty) return;

    final sortedHubs = List<MediaHub>.from(_hubs);
    if (!sortMediaHubsByLibraryOrder(sortedHubs, _libraries.libraries)) return;
    _hubs = sortedHubs;
    safeNotifyListeners();
  }

  List<String> _libraryOrderKeys() => [for (final library in _libraries.libraries) library.globalKey];

  // --- Platform launcher shelf ----------------------------------------------

  /// Sync Continue Watching to the platform launcher shelf. Rapid updates
  /// coalesce: a sync that arrives while one is in flight queues exactly one
  /// follow-up pass with the latest items.
  Future<void> _syncSystemShelf(List<MediaItem> onDeck) async {
    _pendingSystemShelfItems = List<MediaItem>.unmodifiable(onDeck);
    if (_systemShelfSyncFuture != null) {
      await _systemShelfSyncFuture;
      return;
    }

    final syncFuture = _drainSystemShelfSyncQueue();
    _systemShelfSyncFuture = syncFuture;
    await syncFuture;
  }

  Future<void> _drainSystemShelfSyncQueue() async {
    try {
      while (_pendingSystemShelfItems != null) {
        final onDeck = _pendingSystemShelfItems!;
        _pendingSystemShelfItems = null;
        if (isDisposed) return;

        try {
          final settings = await SettingsService.getInstance();
          final syncableOnDeck = onDeck.where((item) {
            final serverId = item.serverId;
            return serverId != null && _multiServer.getClientForServer(ServerId(serverId)) != null;
          }).toList(growable: false);
          await SystemShelfService().syncFromContinueWatching(
            syncableOnDeck,
            _clientForShelfItem,
            hideSpoilers: settings.read(SettingsService.hideSpoilers),
          );
        } catch (e) {
          appLogger.w('Failed to sync system shelf', error: e);
        }
      }
    } finally {
      _systemShelfSyncFuture = null;
    }
  }

  MediaServerClient _clientForShelfItem(ServerId serverId) {
    final direct = _multiServer.getClientForServer(serverId);
    if (direct != null) return direct;
    throw Exception('No owning client available for $serverId');
  }

  @override
  void dispose() {
    _multiServer.removeOnlineServersListener(syncToOnlineServers);
    _hiddenLibraries.removeListener(_onHiddenLibrariesChanged);
    _libraries.removeListener(_onLibrariesChanged);
    _watchStateSubscription?.cancel();
    _watchStateSubscription = null;
    _pendingSystemShelfItems = null;
    super.dispose();
  }
}
