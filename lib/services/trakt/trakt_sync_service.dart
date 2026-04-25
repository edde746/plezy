import 'dart:async';
import 'dart:collection';

import '../../models/trakt/trakt_ids.dart';
import '../../models/trakt/trakt_scrobble_request.dart';
import '../../utils/app_logger.dart';
import '../../utils/watch_state_notifier.dart';
import '../multi_server_manager.dart';
import '../settings_service.dart';
import '../trackers/tracker_constants.dart';
import '../trackers/tracker_id_resolver.dart';
import 'trakt_client.dart';
import 'trakt_constants.dart';
import 'trakt_session.dart';
import 'trakt_sync_queue.dart';

/// One-way push of watched/unwatched events from Plezy to Trakt.
///
/// Subscribes to `WatchStateNotifier` and filters to `{watched, unwatched}`
/// events on movies/episodes. Failures are queued via `TraktSyncQueue` and
/// drained on app foreground, network restore, and at startup.
class TraktSyncService {
  /// Inter-request delay during queue drain to stay under Trakt's
  /// 1000 req / 5 min rate limit.
  static const Duration _queueRequestSpacing = Duration(milliseconds: 50);

  static TraktSyncService? _instance;
  static TraktSyncService get instance => _instance ??= TraktSyncService._();

  TraktSyncService._();

  bool _isInitialized = false;
  bool _isEnabled = false;
  String _activeUserUuid = '';

  TraktClient? _client;
  MultiServerManager? _serverManager;
  StreamSubscription<WatchStateEvent>? _subscription;
  final TraktSyncQueue _queue = TraktSyncQueue();

  /// One resolver per Plex server, kept alive across events so the per-rating-
  /// key GUID cache survives a binge-watch session.
  final Map<String, TrackerIdResolver> _resolvers = {};

  /// Fallback buffer for items that failed to persist to the on-disk queue
  /// (e.g. SharedPreferences write threw). Retried on next `flushQueue`.
  /// Bounded to keep memory pressure finite; oldest items drop first.
  static const int _maxInMemoryFallback = 100;
  final Queue<TraktSyncQueueItem> _inMemoryFallback = Queue<TraktSyncQueueItem>();

  bool _isFlushing = false;

  Future<void> initialize({required MultiServerManager serverManager}) async {
    if (_isInitialized) return;
    _isInitialized = true;
    _serverManager = serverManager;

    final settings = await SettingsService.getInstance();
    _isEnabled = settings.read(SettingsService.enableTraktWatchedSync);

    _subscription = WatchStateNotifier().stream.listen(
      _onWatchStateEvent,
      onError: (Object e, StackTrace st) =>
          appLogger.w('Trakt sync: watch event handler error', error: e, stackTrace: st),
    );
  }

  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
  }

  /// Switch to a different account. Drops cached resolvers (their PlexClients
  /// are tied to the previous user's tokens) and rebinds the queue.
  void rebindToProfile(String userUuid, TraktSession? session, {required void Function() onSessionInvalidated}) {
    _client?.dispose();
    _client = session != null ? TraktClient(session, onSessionInvalidated: onSessionInvalidated) : null;
    _activeUserUuid = userUuid;
    _resolvers.clear();
    if (_client != null) {
      unawaited(flushQueue());
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _client?.dispose();
    _client = null;
    _resolvers.clear();
  }

  bool get _canPush => _isEnabled && _client != null;

  TrackerIdResolver? _resolverFor(String serverId) {
    final cached = _resolvers[serverId];
    if (cached != null) return cached;

    final plexClient = _serverManager?.getClient(serverId);
    if (plexClient == null) return null;

    final resolver = TrackerIdResolver(plexClient, needsFribb: () => false);
    _resolvers[serverId] = resolver;
    return resolver;
  }

  Future<void> _onWatchStateEvent(WatchStateEvent event) async {
    if (!_canPush) return;
    if (event.changeType == WatchStateChangeType.progressUpdate) return;

    final kind = TraktMediaKind.tryFromPlexType(event.mediaType);
    if (kind == null) return;

    final settings = SettingsService.instanceOrNull;
    if (settings != null && !settings.isLibraryAllowedForTracker(TrackerService.trakt, event.librarySectionGlobalKey)) {
      appLogger.d('Trakt sync: library filtered out for ${event.ratingKey}');
      return;
    }

    final op = event.changeType == WatchStateChangeType.watched ? TraktSyncOp.add : TraktSyncOp.remove;
    await _push(
      op: op,
      ratingKey: event.ratingKey,
      serverId: event.serverId,
      kind: kind,
      watchedAtIso: DateTime.now().toUtc().toIso8601String(),
    );
  }

  Future<void> _push({
    required TraktSyncOp op,
    required String ratingKey,
    required String serverId,
    required TraktMediaKind kind,
    required String watchedAtIso,
  }) async {
    final resolver = _resolverFor(serverId);
    if (resolver == null) {
      appLogger.d('Trakt sync: no PlexClient for server $serverId, skipping');
      return;
    }

    TrackerIds? resolved;
    int? season;
    int? number;

    if (kind == TraktMediaKind.movie) {
      resolved = await resolver.resolveForMovie(ratingKey);
    } else {
      // Episode — need show IDs + season/episode index. The WatchStateEvent
      // doesn't carry the index, so fetch episode metadata.
      final plexClient = _serverManager?.getClient(serverId);
      if (plexClient == null) return;
      final episodeMeta = await plexClient.getMetadataWithImages(ratingKey);
      if (episodeMeta == null) return;
      season = episodeMeta.parentIndex;
      number = episodeMeta.index;
      if (season == null || number == null) return;
      resolved = await resolver.resolveShowForEpisode(episodeMeta);
    }

    if (resolved == null) {
      appLogger.d('Trakt sync: no IDs for ${kind.name} $ratingKey, dropping');
      return;
    }

    final ids = TraktIds.fromExternal(resolved.external);
    final body = kind == TraktMediaKind.movie
        ? TraktScrobbleRequest.movie(ids: ids)
        : TraktScrobbleRequest.episode(showIds: ids, season: season!, number: number!);

    final item = TraktSyncQueueItem(
      op: op,
      ratingKey: ratingKey,
      serverId: serverId,
      kind: kind,
      ids: ids,
      season: season,
      number: number,
      watchedAtIso: watchedAtIso,
    );

    await _trySendOrQueue(item, body);
  }

  Future<void> _trySendOrQueue(TraktSyncQueueItem item, TraktScrobbleRequest body) async {
    final client = _client;
    if (client == null) {
      await _persistOrBuffer(item);
      return;
    }
    try {
      await _dispatch(client, item, body);
      appLogger.d('Trakt sync: ${item.op.name} ${item.ratingKey} → ok');
    } catch (e) {
      appLogger.d('Trakt sync: ${item.op.name} ${item.ratingKey} failed, queuing', error: e);
      await _persistOrBuffer(item);
    }
  }

  /// Persist an item to the on-disk queue; fall back to a bounded in-memory
  /// buffer if the disk write throws (e.g. disk full, SAF permission revoked).
  /// Retried at the start of the next `flushQueue` run.
  Future<void> _persistOrBuffer(TraktSyncQueueItem item) async {
    try {
      await _queue.add(_activeUserUuid, item);
    } catch (e, st) {
      appLogger.e(
        'Trakt sync: queue persist failed for ${item.op.name} ${item.ratingKey}, buffering in memory',
        error: e,
        stackTrace: st,
      );
      if (_inMemoryFallback.length >= _maxInMemoryFallback) {
        final dropped = _inMemoryFallback.removeFirst();
        appLogger.w('Trakt sync: in-memory fallback full, dropping ${dropped.op.name} ${dropped.ratingKey}');
      }
      _inMemoryFallback.addLast(item);
    }
  }

  Future<void> _dispatch(TraktClient client, TraktSyncQueueItem item, TraktScrobbleRequest body) {
    return switch (item.op) {
      TraktSyncOp.add => client.addToHistory(body, watchedAt: item.watchedAtIso),
      TraktSyncOp.remove => client.removeFromHistory(body),
    };
  }

  /// Drain the persisted queue. Called on init, on app foreground, and when
  /// `OfflineModeProvider.isOffline` flips false.
  Future<void> flushQueue() async {
    if (_isFlushing) return;
    final client = _client;
    if (client == null) return;
    _isFlushing = true;
    try {
      await _recoverInMemoryFallback();

      await _queue.drainWith(_activeUserUuid, (item) async {
        if (item.attempts >= TraktSyncQueue.maxAttempts) {
          appLogger.w('Trakt sync: dropping ${item.op.name} ${item.ratingKey} after ${item.attempts} attempts');
          return null;
        }
        try {
          await _dispatch(client, item, _bodyFor(item));
          appLogger.d('Trakt sync: drained ${item.op.name} ${item.ratingKey}');
          await Future<void>.delayed(_queueRequestSpacing);
          return null;
        } catch (e) {
          appLogger.d('Trakt sync: drain failed for ${item.ratingKey}, will retry', error: e);
          await Future<void>.delayed(_queueRequestSpacing);
          return item.incrementAttempts();
        }
      });
    } finally {
      _isFlushing = false;
    }
  }

  /// Try to move items buffered in memory (because prior disk writes failed)
  /// back onto the persistent queue. Best-effort; items that still can't be
  /// persisted stay in the buffer for the next flush.
  Future<void> _recoverInMemoryFallback() async {
    if (_inMemoryFallback.isEmpty) return;
    final snapshot = List<TraktSyncQueueItem>.from(_inMemoryFallback);
    _inMemoryFallback.clear();
    for (final item in snapshot) {
      await _persistOrBuffer(item);
    }
  }

  TraktScrobbleRequest _bodyFor(TraktSyncQueueItem item) {
    return switch (item.kind) {
      TraktMediaKind.movie => TraktScrobbleRequest.movie(ids: item.ids),
      TraktMediaKind.episode => TraktScrobbleRequest.episode(
        showIds: item.ids,
        season: item.season!,
        number: item.number!,
      ),
    };
  }
}
