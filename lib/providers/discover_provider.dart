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
import '../utils/coalesced_load_coordinator.dart';
import '../utils/deletion_notifier.dart';
import '../utils/global_key_utils.dart';
import '../utils/media_hub_ordering.dart';
import '../utils/watch_state_notifier.dart';
import 'hidden_libraries_provider.dart';
import 'libraries_provider.dart';
import 'multi_server_provider.dart';

enum DiscoverLoadState { initial, loading, loaded, error }

/// Owns the Discover tab's data: the Continue Watching row and the home hub
/// list, including the refresh policy that used to live in the screen —
/// durable watch events refresh only Continue Watching (one on-deck call,
/// zero hub refetches), playback progress patches the visible row in place,
/// deletions drop the item from every visible list in place and then refresh
/// only Continue Watching, hidden-library changes trigger a full reload,
/// library-order changes re-sort hubs in place without refetching, and the
/// platform launcher shelf syncs from every on-deck update.
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

  DiscoverProvider(
    this._multiServer,
    this._hiddenLibraries,
    this._libraries, {
    required this.isProfileBinding,
    Future<void> Function(List<MediaItem>)? syncSystemShelf,
  }) : _syncSystemShelfOverride = syncSystemShelf {
    _loadCoordinator = CoalescedLoadCoordinator<String>(onFull: _loadOnce, onDelta: _loadDeltaOnce);
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
    _deletionSubscription = subscribeToHierarchicalEvents<DeletionEvent>(
      notifier: DeletionNotifier(),
      mounted: () => !isDisposed,
      serverId: () => null,
      globalKeys: () => _deletionGlobalKeys,
      itemIds: () => _deletionIds,
      onEvent: _onDeletion,
    );
  }

  final MultiServerProvider _multiServer;
  final HiddenLibrariesProvider _hiddenLibraries;
  final LibrariesProvider _libraries;

  /// Whether the profile binder is still wiring servers — a no-servers load
  /// during binding stays in the loading state instead of flashing an error,
  /// and a zero-success pass during binding stays in the loading state
  /// instead of flashing the empty placeholder (main_screen primes another
  /// load once binding settles).
  final bool Function() isProfileBinding;
  final Future<void> Function(List<MediaItem>)? _syncSystemShelfOverride;

  StreamSubscription<WatchStateEvent>? _watchStateSubscription;
  StreamSubscription<DeletionEvent>? _deletionSubscription;

  List<MediaItem> _onDeck = [];
  List<MediaHub> _hubs = [];
  bool _hasMoreContinueWatching = false;
  DiscoverLoadState _onDeckState = DiscoverLoadState.initial;
  DiscoverLoadState _hubsState = DiscoverLoadState.initial;
  String? _errorMessage;
  int _loadGeneration = 0;
  int _contentRevision = 0;
  Future<void>? _continueWatchingRefreshFuture;
  bool _continueWatchingRefreshQueued = false;

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

  late final CoalescedLoadCoordinator<String> _loadCoordinator;

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
    if (isDisposed || onlineServerIds.isEmpty || isProfileBinding()) return Future<void>.value();
    if (_onDeckState == DiscoverLoadState.loaded &&
        _hubsState == DiscoverLoadState.loaded &&
        _fullyLoadedServerIds.containsAll(onlineServerIds)) {
      return Future<void>.value();
    }
    // Nothing (or a failed pass) to merge into yet — run the full load.
    if (_onDeckState != DiscoverLoadState.loaded || _hubsState != DiscoverLoadState.loaded) return load();
    return _loadCoordinator.requestDelta(onlineServerIds.difference(_fullyLoadedServerIds));
  }

  /// Full load of Continue Watching + hubs. Concurrent calls coalesce into
  /// the in-flight pass plus at most one trailing pass (so a request that
  /// arrives mid-load still observes its own fresh fetch).
  Future<void> load() {
    if (isDisposed) return Future<void>.value();
    return _loadCoordinator.requestFull();
  }

  Future<void> _loadOnce() async {
    // Yield to the microtask queue before the first notify so a load()
    // kicked off during build (the screen's initState) doesn't mark
    // listening widgets dirty mid-build.
    await null;
    if (isDisposed) return;
    ++_contentRevision;
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
      if (isDisposed) return;
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

      // A pass in which zero servers succeeded is never authoritative: it
      // must not wipe existing content, and it may only commit "loaded,
      // empty" when the failure is settled — not a client-side abort
      // (teardown mid-fetch) and not mid-binding. In both of those cases a
      // follow-up load is guaranteed (binding-settle prime, or
      // syncToOnlineServers falling through to load() while not loaded).
      final fetchedOnDeck = await onDeckFuture;
      if (isDisposed) return;
      if (fetchedOnDeck.succeededServerIds.isEmpty && _onDeck.isNotEmpty) {
        // Keep the stale rows; the empty succeeded set makes the next status
        // emission refetch every server.
        appLogger.w('DiscoverProvider: on-deck pass failed on all servers; keeping previous items');
        _onDeckState = DiscoverLoadState.loaded;
        _loadedOnDeckServerIds = fetchedOnDeck.succeededServerIds;
        safeNotifyListeners();
      } else if (fetchedOnDeck.succeededServerIds.isEmpty &&
          (fetchedOnDeck.cancelledServerIds.isNotEmpty || isProfileBinding())) {
        // Disrupted with nothing to show yet: stay in loading so the screen
        // keeps its skeleton instead of flashing the empty placeholder.
        // Don't return — the hubs fetch is still in flight below.
        appLogger.d('DiscoverProvider: on-deck pass disrupted with no prior content; keeping loading state');
      } else {
        _applyOnDeck(fetchedOnDeck.items);
        _onDeckState = DiscoverLoadState.loaded;
        _loadedOnDeckServerIds = fetchedOnDeck.succeededServerIds;
        _loadGeneration++;
        safeNotifyListeners();
        unawaited(_syncSystemShelf(_onDeck));
      }

      final fetchedHubs = await hubsFuture;
      if (isDisposed) return;

      if (fetchedHubs.succeededServerIds.isEmpty && _hubs.isNotEmpty) {
        appLogger.w('DiscoverProvider: hub pass failed on all servers; keeping previous hubs');
        _hubsState = DiscoverLoadState.loaded;
        _loadedHubServerIds = fetchedHubs.succeededServerIds;
        safeNotifyListeners();
        return;
      }
      if (fetchedHubs.succeededServerIds.isEmpty && (fetchedHubs.cancelledServerIds.isNotEmpty || isProfileBinding())) {
        appLogger.d('DiscoverProvider: hub pass disrupted with no prior content; keeping loading state');
        return;
      }

      final filteredHubs = _filterDiscoverHubs(fetchedHubs.hubs);
      sortMediaHubsByLibraryOrder(filteredHubs, _libraries.libraries);

      appLogger.d('DiscoverProvider: ${_onDeck.length} on-deck items, ${filteredHubs.length} hubs');
      _hubs = filteredHubs;
      _hubsState = DiscoverLoadState.loaded;
      _loadedHubServerIds = fetchedHubs.succeededServerIds;
      safeNotifyListeners();
    } catch (e) {
      if (isDisposed) return;
      appLogger.e('Failed to load discover content', error: e);
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
    ++_contentRevision;
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
      if (isDisposed) return;
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
      if (isDisposed) return;
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

  /// Background refresh of Continue Watching only. Concurrent events coalesce
  /// into the active request plus at most one trailing fresh request.
  Future<void> refreshContinueWatching() {
    final active = _continueWatchingRefreshFuture;
    if (active != null) {
      _continueWatchingRefreshQueued = true;
      return active;
    }
    late final Future<void> refresh;
    refresh = _runContinueWatchingRefreshes().whenComplete(() {
      if (identical(_continueWatchingRefreshFuture, refresh)) {
        _continueWatchingRefreshFuture = null;
      }
    });
    _continueWatchingRefreshFuture = refresh;
    return refresh;
  }

  Future<void> _runContinueWatchingRefreshes() async {
    do {
      _continueWatchingRefreshQueued = false;
      await _refreshContinueWatchingOnce();
    } while (_continueWatchingRefreshQueued && !isDisposed);
  }

  Future<void> _refreshContinueWatchingOnce() async {
    try {
      if (!_multiServer.hasConnectedServers) return;
      final revision = _contentRevision;
      final hiddenKeys = Set<String>.of(_hiddenLibraries.hiddenLibraryKeys);
      final fetched = await _multiServer.aggregationService.getOnDeckFromAllServers(
        limit: _continueWatchingProbeLimit,
        hiddenLibraryKeys: hiddenKeys,
      );
      if (isDisposed) return;
      if (revision != _contentRevision) {
        _continueWatchingRefreshQueued = true;
        return;
      }
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

  /// Refetch a single item (post-edit refresh from a hub row) through its
  /// source server and swap it into whichever lists contain that qualified
  /// identity.
  Future<void> updateItem(MediaItem source) async {
    final serverId = source.serverId;
    if (serverId == null) return;

    try {
      final updated = await _multiServer.getClientForServer(ServerId(serverId))?.fetchItem(source.id);
      if (updated == null || isDisposed) return;
      _updateItemInLists(source.globalKey, updated);
      safeNotifyListeners();
    } catch (_) {
      // Silently fail — the item will refresh on the next full reload.
    }
  }

  void _updateItemInLists(String sourceGlobalKey, MediaItem updatedItem) {
    final onDeckIndex = _onDeck.indexWhere((item) => item.globalKey == sourceGlobalKey);
    if (onDeckIndex != -1) {
      _onDeck = List.of(_onDeck)..[onDeckIndex] = updatedItem;
    }

    for (var i = 0; i < _hubs.length; i++) {
      final hub = _hubs[i];
      final itemIndex = hub.items.indexWhere((item) => item.globalKey == sourceGlobalKey);
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
    if (event.changeType == WatchStateChangeType.progressUpdate && event.isNowWatched != true) {
      final viewOffset = event.viewOffset;
      final index = _onDeck.indexWhere((item) => item.globalKey == event.globalKey);
      if (viewOffset != null && index != -1 && _onDeck[index].viewOffsetMs != viewOffset) {
        _onDeck = List.of(_onDeck)..[index] = _onDeck[index].copyWith(viewOffsetMs: viewOffset);
        safeNotifyListeners();
        unawaited(_syncSystemShelf(_onDeck));
      }
      return;
    }

    if (event.changeType == WatchStateChangeType.removedFromContinueWatching) {
      final remaining = _onDeck.where((item) => item.id != event.itemId).toList();
      if (remaining.length != _onDeck.length) {
        _onDeck = remaining;
        safeNotifyListeners();
      }
    }
    unawaited(refreshContinueWatching());
  }

  /// Deletions can affect any visible list, so the filter covers on-deck and
  /// hub items plus their parents (a deleted season/show takes its visible
  /// episodes with it).
  Set<String>? get _deletionIds {
    final keys = <String>{};
    void addItem(MediaItem item) {
      keys.add(item.id);
      if (item.parentId != null) keys.add(item.parentId!);
      if (item.grandparentId != null) keys.add(item.grandparentId!);
    }

    _onDeck.forEach(addItem);
    for (final hub in _hubs) {
      hub.items.forEach(addItem);
    }
    return keys;
  }

  Set<String>? get _deletionGlobalKeys {
    final keys = <String>{};
    bool addItem(MediaItem item) {
      final serverId = item.serverId;
      if (serverId == null) return false;

      keys.add(buildGlobalKey(ServerId(serverId), item.id));
      if (item.parentId != null) keys.add(buildGlobalKey(ServerId(serverId), item.parentId!));
      if (item.grandparentId != null) keys.add(buildGlobalKey(ServerId(serverId), item.grandparentId!));
      return true;
    }

    for (final item in _onDeck) {
      if (!addItem(item)) return null;
    }
    for (final hub in _hubs) {
      for (final item in hub.items) {
        if (!addItem(item)) return null;
      }
    }
    return keys;
  }

  void _onDeletion(DeletionEvent event) {
    // On-deck and hubs are server-backed: a download-only deletion leaves the
    // server item in place, so it must not evict anything here.
    if (event.isDownloadOnly) return;

    bool affected(MediaItem item) =>
        item.id == event.itemId || item.parentId == event.itemId || item.grandparentId == event.itemId;

    var changed = false;
    final remainingOnDeck = _onDeck.where((item) => !affected(item)).toList();
    if (remainingOnDeck.length != _onDeck.length) {
      _onDeck = remainingOnDeck;
      changed = true;
    }
    for (var i = 0; i < _hubs.length; i++) {
      final hub = _hubs[i];
      final newItems = hub.items.where((item) => !affected(item)).toList();
      if (newItems.length != hub.items.length) {
        _hubs = List.of(_hubs)..[i] = hub.copyWith(items: newItems);
        changed = true;
      }
    }
    if (changed) safeNotifyListeners();
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
    if (isDisposed) return;
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
          final syncOverride = _syncSystemShelfOverride;
          if (syncOverride != null) {
            await syncOverride(onDeck);
            continue;
          }
          final settings = await SettingsService.getInstance();
          if (isDisposed) return;
          final syncableOnDeck = onDeck
              .where((item) {
                final serverId = item.serverId;
                return serverId != null && _multiServer.getClientForServer(ServerId(serverId)) != null;
              })
              .toList(growable: false);
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
      if (!isDisposed) _systemShelfSyncFuture = null;
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
    _deletionSubscription?.cancel();
    _deletionSubscription = null;
    _loadCoordinator.dispose();
    _pendingSystemShelfItems = null;
    super.dispose();
  }
}
