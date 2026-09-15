import 'library_event_socket.dart';

/// Plex realtime notifications: `ws(s)://<server>/:/websockets/notifications`.
///
/// Every frame is a `NotificationContainer`. One library scan floods the
/// socket (156 frames measured on Plex 1.43 for a single new movie: 80
/// `activity`, 52 `progress`, 14 `timeline`, plus unrelated `playing`
/// session traffic), so only settled `timeline` entries feed the debounce:
///
/// ```json
/// {"NotificationContainer": {"type": "timeline", "TimelineEntry": [
///   {"identifier": "com.plexapp.plugins.library", "sectionID": "1",
///    "itemID": "10141", "type": 1, "state": 5, "metadataState": "created"}]}}
/// ```
///
/// `state` walks 0→5 while an item is scanned/matched/analyzed; `state == 5`
/// is the settled commit. A deletion emits the same entry with `type: -1`
/// (measured; the kind field is replaced, there is no separate deleted state).
/// Adds and metadata updates are indistinguishable at settle time, so both
/// advisory flags are set for non-deletions.
class PlexLibraryEventSocket extends LibraryEventSocket {
  PlexLibraryEventSocket({
    required super.serverId,
    required this.baseUrl,
    required this.token,
    super.channelFactory,
    super.debounce = const Duration(seconds: 10),
    super.retryBaseDelay,
    super.maxConnectAttempts,
  });

  /// Read live so an endpoint failover or token refresh lands on the next
  /// connect attempt.
  final String Function() baseUrl;
  final String? Function() token;

  /// Only timeline entries from the library plugin describe library content;
  /// other identifiers carry playlist/butler/provider timelines.
  static const _libraryIdentifier = 'com.plexapp.plugins.library';

  /// Timeline `state` for a settled (fully committed) entry.
  static const _stateSettled = 5;

  /// Timeline `type` marking a deleted item.
  static const _typeDeleted = -1;

  @override
  Uri buildUri() {
    // Keep any reverse-proxy path prefix from the base URL, like the
    // MediaBrowser socket does.
    final base = webSocketBase(baseUrl());
    return base.replace(path: '${base.path}/:/websockets/notifications', queryParameters: {'X-Plex-Token': ?token()});
  }

  @override
  void onFrame(dynamic frame) {
    final decoded = tryDecodeJsonFrame(frame);
    final container = decoded?['NotificationContainer'];
    if (container is! Map) return;
    if (container['type'] != 'timeline') return;
    final entries = container['TimelineEntry'];
    if (entries is! List) return;
    for (final entry in entries) {
      if (entry is! Map) continue;
      if (entry['identifier'] != _libraryIdentifier) continue;
      if (entry['state'] != _stateSettled) continue;
      final sectionId = entry['sectionID']?.toString();
      final itemId = entry['itemID']?.toString();
      final removed = entry['type'] == _typeDeleted;
      scheduleLibraryChange(
        libraryIds: [if (sectionId != null && sectionId.isNotEmpty) sectionId],
        removedItemIds: [if (removed && itemId != null && itemId.isNotEmpty) itemId],
        added: !removed,
        updated: !removed,
        removed: removed,
      );
    }
  }
}
