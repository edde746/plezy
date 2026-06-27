import 'dart:async';

import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../database/watchlist_operations.dart';
import '../media/media_item.dart';
import '../mixins/disposable_change_notifier_mixin.dart';

/// Provider for reactive, profile-scoped watchlist state.
///
/// Items are loaded via a Drift [watchWatchlist] stream that re-emits on every
/// insert or delete. [toggleBookmark] applies an optimistic local update and
/// delegates to the database; the stream reconciles state shortly after.
class WatchlistProvider extends ChangeNotifier with DisposableChangeNotifierMixin {
  final AppDatabase _database;

  /// All items keyed by their [globalKey].
  Map<String, WatchlistItem> _items = {};

  StreamSubscription<List<WatchlistItem>>? _watchSub;
  String? _activeProfileId;

  WatchlistProvider({required AppDatabase database}) : _database = database;

  // ---------------------------------------------------------------------------
  // Public read-only state
  // ---------------------------------------------------------------------------

  /// Returns an unmodifiable view of all watchlist items.
  Map<String, WatchlistItem> get items => Map.unmodifiable(_items);

  /// Set of all bookmarked global keys (O(1) lookups).
  Set<String> get bookmarkedKeys => _items.keys.toSet();

  /// Returns `true` when [globalKey] is currently bookmarked.
  bool isBookmarked(String globalKey) => _items.containsKey(globalKey);

  /// Items filtered to movies only.
  List<WatchlistItem> get movies =>
      _items.values.where((i) => i.kind == 'movie').toList();

  /// Items filtered to shows only.
  List<WatchlistItem> get shows =>
      _items.values.where((i) => i.kind == 'show').toList();

  /// Items filtered to seasons only.
  List<WatchlistItem> get seasons =>
      _items.values.where((i) => i.kind == 'season').toList();

  /// Items filtered to episodes only.
  List<WatchlistItem> get episodes =>
      _items.values.where((i) => i.kind == 'episode').toList();

  // ---------------------------------------------------------------------------
  // Profile lifecycle
  // ---------------------------------------------------------------------------

  /// Switch the watchlist scope to [profileId]. Cancels any existing
  /// subscription, starts a new [watchWatchlist] stream for the given profile,
  /// and populates [_items] from the initial snapshot.
  void setActiveProfileId(String? profileId) {
    if (_activeProfileId == profileId) return;
    _activeProfileId = profileId;

    _watchSub?.cancel();
    _watchSub = null;

    if (profileId == null) {
      _items = {};
      safeNotifyListeners();
      return;
    }

    _watchSub = _database.watchWatchlist(profileId).listen(
      _onWatchlistUpdate,
      onError: (Object error) {
        // Silently handle stream errors — the next profile switch or retoggle
        // will repopulate from a fresh snapshot.
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  /// Toggles the bookmark for [metadata]. Adds the item to the watchlist if it
  /// is not currently bookmarked; removes it if it is. Updates [_items]
  /// immediately for responsive UI feedback.
  Future<void> toggleBookmark(MediaItem metadata) async {
    final profileId = _activeProfileId;
    if (profileId == null) return;

    final globalKey = metadata.globalKey;
    final serverId = metadata.serverId ?? '';

    final added = await _database.toggleBookmark(
      profileId: profileId,
      serverId: serverId,
      ratingKey: metadata.id,
      globalKey: globalKey,
      kind: metadata.kind.id,
      title: metadata.title ?? '',
      thumbPath: metadata.thumbPath,
      backdropPath: metadata.artPath,
      year: metadata.year,
      index: metadata.index,
      parentTitle: metadata.parentTitle,
    );

    // Optimistic local update — the stream will reconcile shortly after.
    if (added) {
      _items[globalKey] = WatchlistItem(
        profileId: profileId,
        globalKey: globalKey,
        serverId: serverId,
        clientScopeId: null,
        ratingKey: metadata.id,
        kind: metadata.kind.id,
        title: metadata.title ?? '',
        thumbPath: metadata.thumbPath,
        backdropPath: metadata.artPath,
        year: metadata.year,
        index: metadata.index,
        parentTitle: metadata.parentTitle,
        addedAt: DateTime.now().millisecondsSinceEpoch,
      );
    } else {
      _items.remove(globalKey);
    }
    safeNotifyListeners();
  }

  /// Deletes all watchlist rows for the active profile.
  Future<void> clearAll() async {
    final profileId = _activeProfileId;
    if (profileId == null) return;
    await _database.clearAll(profileId);
    // The stream subscription will emit an empty list and update _items.
    // Apply local update immediately for responsiveness.
    _items = {};
    safeNotifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Stream handling
  // ---------------------------------------------------------------------------

  void _onWatchlistUpdate(List<WatchlistItem> items) {
    _items = {for (final item in items) item.globalKey: item};
    safeNotifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _watchSub?.cancel();
    _watchSub = null;
    super.dispose();
  }
}
