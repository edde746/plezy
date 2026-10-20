import 'package:flutter/foundation.dart';

import '../../media/media_item.dart';
import '../../media/media_version.dart';

/// One file in this user's libraries that a room can play: a version of an
/// item on one server. It is the `ref` the Open Watch Party SDK hands back with
/// a choice, and the one the player attaches with once it has that file open.
///
/// Copies compare by server, item and version only, so the player's own
/// description of what it opened equals the resolver's candidate for the same
/// file, and an open made for another version never binds to this one.
@immutable
final class WatchCopy {
  const WatchCopy({required this.serverId, required this.itemId, required this.versionId, this.item, this.version});

  /// The copy of [version] of [item]. [item] must carry its server.
  factory WatchCopy.of(MediaItem item, MediaVersion? version) =>
      WatchCopy(serverId: item.serverId!, itemId: item.id, versionId: version?.id ?? '', item: item, version: version);

  final String serverId;
  final String itemId;

  /// The backend's version (Plex `Media`, Jellyfin/Emby media source) id; empty
  /// when the item lists no versions.
  final String versionId;

  /// The item as last fetched, for display and for opening without a lookup.
  final MediaItem? item;
  final MediaVersion? version;

  /// The version's length: its parts back to back, or the item's own length
  /// when the item has only this one version.
  int? get durationMs => versionDurationMs(item, version);

  @override
  bool operator ==(Object other) =>
      other is WatchCopy && other.serverId == serverId && other.itemId == itemId && other.versionId == versionId;

  @override
  int get hashCode => Object.hash(serverId, itemId, versionId);

  @override
  String toString() => 'WatchCopy($serverId:$itemId${versionId.isEmpty ? '' : '#$versionId'})';
}

/// [version]'s length as the server reports it: the sum of its parts when
/// every part has one, else the item's own length when [version] is its only
/// version (or it lists none). Null when neither is known.
int? versionDurationMs(MediaItem? item, MediaVersion? version) {
  final parts = version?.parts ?? const [];
  if (parts.isNotEmpty && parts.every((part) => (part.durationMs ?? 0) > 0)) {
    return parts.fold<int>(0, (sum, part) => sum + part.durationMs!);
  }
  final versions = item?.mediaVersions ?? const <MediaVersion>[];
  final only = versions.length <= 1;
  final itemDuration = item?.durationMs;
  return only && itemDuration != null && itemDuration > 0 ? itemDuration : null;
}
