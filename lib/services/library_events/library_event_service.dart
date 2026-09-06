import 'dart:async';

import '../../media/library_change_event.dart';
import '../../media/media_kind.dart';
import '../../media/media_server_client.dart';
import '../../utils/app_logger.dart';
import '../../utils/deletion_notifier.dart';
import '../../utils/library_content_notifier.dart';
import '../multi_server_manager.dart';

/// Runs one [LibraryEventChannel] per online server and fans their events out
/// through [LibraryContentNotifier] (#1646).
///
/// App-global: constructed next to [MultiServerManager] in `main.dart` and
/// disposed with it. Which channels run follows two inputs:
/// - the manager's [MultiServerManager.statusStream] (server online/offline,
///   client or committed authentication session replaced on profile switch);
/// - app lifecycle via [suspend]/[resume] — sockets are foreground-only on
///   mobile, mirroring the companion remote's backoff pause. [resume] also
///   re-arms channels that exhausted their reconnect attempts.
///
/// Everything here degrades silently; the stale-refresh paths remain the
/// fallback when a socket cannot be established.
class LibraryEventService {
  LibraryEventService(this._serverManager, {LibraryContentNotifier? notifier})
    : _notifier = notifier ?? LibraryContentNotifier() {
    _statusSubscription = _serverManager.statusStream.listen((_) => sync());
  }

  final MultiServerManager _serverManager;
  final LibraryContentNotifier _notifier;

  StreamSubscription<Map<String, bool>>? _statusSubscription;
  final Map<String, _ManagedChannel> _channels = {};
  bool _suspended = false;
  bool _disposed = false;

  /// Server ids with a managed channel right now (running or backing off).
  Set<String> get activeServerIds => Set.unmodifiable(_channels.keys);

  /// Reconcile the managed channels against the manager's current online
  /// clients. Runs on every status emission; call after [resume] or a
  /// registration change that has no status emission of its own.
  void sync() {
    if (_disposed || _suspended) return;
    final online = _serverManager.onlineClients;

    // A healthy Plex client can commit a new profile/token in place. Its
    // established websocket still belongs to the previous authentication
    // session even though the HTTP client and endpoint are unchanged.
    final stale = <String>[];
    _channels.forEach((serverId, managed) {
      if (!identical(online[serverId], managed.client) ||
          !identical(managed.authenticationSessionId, managed.client.authenticationSessionId)) {
        stale.add(serverId);
      }
    });
    for (final serverId in stale) {
      _stopChannel(serverId);
    }

    for (final entry in online.entries) {
      final serverId = entry.key;
      final client = entry.value;
      final retained = _channels[serverId];
      if (retained != null) {
        // Re-arm a channel whose reconnect attempts were exhausted (a
        // transient outage longer than the backoff budget); start() is a
        // no-op while the channel is running or backing off.
        retained.channel.start();
        continue;
      }
      if (!client.capabilities.libraryChangeEvents) continue;
      final authenticationSessionId = client.authenticationSessionId;
      final channel = client.createLibraryEventChannel();
      if (channel == null) continue;
      // Cancelled in [_stopChannel]; tracked through [_ManagedChannel].
      // ignore: cancel_subscriptions
      final subscription = channel.events.listen((event) {
        if (_disposed || _suspended || !identical(_channels[serverId]?.channel, channel)) return;
        // A commit can precede the manager's batched status emission. Reject
        // old frames and trailing coalesced events immediately, including an
        // A -> B -> A switch that ends with the same token/scope values.
        if (!identical(authenticationSessionId, client.authenticationSessionId)) {
          _stopChannel(serverId);
          return;
        }
        _handleEvent(event);
      });
      _channels[serverId] = _ManagedChannel(client, authenticationSessionId, channel, subscription);
      appLogger.d('LibraryEventService: starting push channel for $serverId');
      channel.start();
    }
  }

  /// A bulk removal (a whole library or show deleted) can name hundreds of
  /// items; past this the per-item drops stop paying for themselves and the
  /// coarse refetch owns the update.
  static const int _maxPerItemRemovals = 25;

  void _handleEvent(LibraryChangeEvent event) {
    // Exact carve-out (Plex Web parity): removals name items the app may be
    // displaying, so drop them in place everywhere via the existing deletion
    // bus before the coarse event schedules its debounced refetch. The kind
    // and parent chain are unknown at this boundary — direct id matches and
    // consumers' own parent lookups still apply; cascades settle with the
    // refetch.
    if (event.removedItemIds.isNotEmpty && event.removedItemIds.length <= _maxPerItemRemovals) {
      for (final itemId in event.removedItemIds) {
        DeletionNotifier().notify(
          DeletionEvent(
            itemId: itemId,
            serverId: event.serverId,
            parentChain: const [],
            mediaType: MediaKind.unknown.id,
            origin: DeletionOrigin.serverPush,
          ),
        );
      }
    }
    _notifier.notifyChanged(event);
  }

  /// Stop every channel but remember nothing was torn down permanently;
  /// [resume] rebuilds from the manager's live state.
  void suspend() {
    if (_disposed || _suspended) return;
    _suspended = true;
    for (final serverId in _channels.keys.toList()) {
      _stopChannel(serverId);
    }
  }

  /// Reconcile on every foreground entry, including desktop where channels
  /// were never suspended but may have exhausted their reconnect budget.
  void resume() {
    if (_disposed) return;
    _suspended = false;
    sync();
  }

  void _stopChannel(String serverId) {
    final managed = _channels.remove(serverId);
    if (managed == null) return;
    unawaited(managed.subscription.cancel());
    managed.channel.dispose();
  }

  void dispose() {
    if (_disposed) return;
    _suspended = true;
    for (final serverId in _channels.keys.toList()) {
      _stopChannel(serverId);
    }
    unawaited(_statusSubscription?.cancel());
    _statusSubscription = null;
    _disposed = true;
  }
}

class _ManagedChannel {
  _ManagedChannel(this.client, this.authenticationSessionId, this.channel, this.subscription);

  final MediaServerClient client;
  final Object authenticationSessionId;
  final LibraryEventChannel channel;
  final StreamSubscription<LibraryChangeEvent> subscription;
}
