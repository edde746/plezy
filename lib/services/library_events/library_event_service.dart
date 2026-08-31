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
///   client replaced on profile switch);
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

    // Tear down channels whose server went offline or whose client was
    // replaced (profile switch rebinds a new client under the same id — the
    // old channel holds callbacks into the dead client).
    final stale = <String>[];
    _channels.forEach((serverId, managed) {
      if (!identical(online[serverId], managed.client)) stale.add(serverId);
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
      final channel = client.createLibraryEventChannel();
      if (channel == null) continue;
      // Cancelled in [_stopChannel]; tracked through [_ManagedChannel].
      // ignore: cancel_subscriptions
      final subscription = channel.events.listen(_handleEvent);
      _channels[serverId] = _ManagedChannel(client, channel, subscription);
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

  void resume() {
    if (_disposed || !_suspended) return;
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
  _ManagedChannel(this.client, this.channel, this.subscription);

  final MediaServerClient client;
  final LibraryEventChannel channel;
  final StreamSubscription<LibraryChangeEvent> subscription;
}
