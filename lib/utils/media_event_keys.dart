import '../media/ids.dart';
import '../media/media_item.dart';
import 'app_logger.dart';
import 'global_key_utils.dart';

/// Builds the id filter for a screen showing [items].
///
/// Each item contributes itself plus its parent and grandparent, because an
/// event on a season or show also changes how its episodes render.
Set<String> hierarchicalEventIds(Iterable<MediaItem> items) {
  final keys = <String>{};
  for (final item in items) {
    keys.add(item.id);
    if (item.parentId != null) keys.add(item.parentId!);
    if (item.grandparentId != null) keys.add(item.grandparentId!);
  }
  return keys;
}

/// The [hierarchicalEventIds] filter expressed as `serverId:ratingKey` keys.
///
/// Items without a server id fall back to [fallbackServerId]; if that is also
/// missing the whole filter collapses to `null`, which callers use to fall back
/// to id-only matching rather than silently under-matching.
Set<String>? hierarchicalEventGlobalKeys(Iterable<MediaItem> items, {String? fallbackServerId}) {
  final keys = <String>{};
  for (final item in items) {
    final rawServerId = item.serverId ?? fallbackServerId;
    if (rawServerId == null) return null;

    final serverId = ServerId(rawServerId);
    keys.add(buildGlobalKey(serverId, item.id));
    if (item.parentId != null) keys.add(buildGlobalKey(serverId, item.parentId!));
    if (item.grandparentId != null) keys.add(buildGlobalKey(serverId, item.grandparentId!));
  }
  return keys;
}

/// The [ServerId] an event emitted for [item] should carry, or `null` — after
/// warning as `<notifier>: … skipping <event> event` — when the item carries
/// none, since an event without a server id cannot be routed to subscribers.
ServerId? serverIdForEvent(MediaItem item, {required String notifier, required String event}) {
  final serverId = serverIdOrNull(item.serverId);
  if (serverId == null) {
    appLogger.w('$notifier: missing serverId for ${item.id}, skipping $event event');
  }
  return serverId;
}
