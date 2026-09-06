import 'ids.dart';

/// One coalesced "this server's library content changed" signal from a
/// server push channel (#1646).
///
/// Deliberately coarse for additions and updates: raw notifications arrive
/// mid-scan when backends disagree about what an id even means (Plex emits
/// per-state timeline floods, MediaBrowser batches server-side), and every
/// consumer responds by refetching its own views anyway. The one exact
/// carve-out is [removedItemIds]: a removal names an item the app may be
/// displaying right now, so those ids ride along for in-place drops through
/// `DeletionNotifier` — the same split Plex Web uses (deletions patch stores
/// directly; additions go through container refetch).
class LibraryChangeEvent {
  /// Server whose library changed.
  final ServerId serverId;

  /// Backend-native ids of the affected libraries (Plex section ids,
  /// MediaBrowser collection-folder ids). Empty when the backend did not say,
  /// which consumers must read as [targetsWholeServer] — never as "nothing".
  final Set<String> libraryIds;

  /// Backend-native ids of removed items, when the backend named them (Plex
  /// settled `type: -1` timeline entries, MediaBrowser `ItemsRemoved`).
  final Set<String> removedItemIds;

  /// Advisory flags describing what the change contained. A backend that
  /// cannot distinguish (Plex settles adds and metadata updates identically)
  /// sets the closest superset.
  final bool itemsAdded;
  final bool itemsRemoved;
  final bool itemsUpdated;

  const LibraryChangeEvent({
    required this.serverId,
    this.libraryIds = const {},
    this.removedItemIds = const {},
    this.itemsAdded = false,
    this.itemsRemoved = false,
    this.itemsUpdated = false,
  });

  bool get hasChanges => itemsAdded || itemsRemoved || itemsUpdated;

  /// Whether the change's scope is unidentified and therefore covers every
  /// library on [serverId]. Absorbing under coalescing: merging any event
  /// with a whole-server one must yield a whole-server event, never a
  /// narrower union of the named ids.
  bool get targetsWholeServer => libraryIds.isEmpty;

  @override
  String toString() =>
      'LibraryChangeEvent($serverId, libraries: $libraryIds, '
      'added: $itemsAdded, removed: $itemsRemoved (${removedItemIds.length} ids), updated: $itemsUpdated)';
}

/// A live push subscription to one server's library-change notifications.
///
/// Implementations own the websocket, keepalive, parsing, per-backend
/// debouncing, and reconnect backoff; [LibraryEventService] owns *which*
/// channels run (server online/offline, app foreground/background). Connect
/// failures degrade silently — the stale-refresh paths remain the fallback —
/// so a reverse proxy without websocket upgrade support must never surface
/// an error to the user.
abstract class LibraryEventChannel {
  /// Coalesced change events. Broadcast; never errors.
  Stream<LibraryChangeEvent> get events;

  /// Begin connecting (idempotent while running). Failures retry with
  /// bounded backoff, then go quiet until the next [start].
  void start();

  /// Drop the connection and all retry state. Safe to call repeatedly;
  /// [start] may be called again afterwards.
  void stop();

  /// [stop] plus closing [events]. The channel is unusable afterwards.
  void dispose();
}
