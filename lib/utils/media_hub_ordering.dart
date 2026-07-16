import '../media/media_hub.dart';
import '../media/ids.dart';
import '../media/media_library.dart';
import 'global_key_utils.dart';

/// Sorts home hubs by the user's library order. Hubs without a known library
/// stay after known-library hubs, preserving their relative server order.
bool sortMediaHubsByLibraryOrder(List<MediaHub> hubs, List<MediaLibrary> libraryOrder) {
  if (hubs.length < 2 || libraryOrder.isEmpty) return false;

  final orderByGlobalKey = <String, int>{};
  for (var i = 0; i < libraryOrder.length; i++) {
    orderByGlobalKey.putIfAbsent(libraryOrder[i].globalKey, () => i);
  }

  final indexedHubs = [for (var i = 0; i < hubs.length; i++) (index: i, hub: hubs[i])];
  indexedHubs.sort((a, b) {
    final aIndex = _hubLibraryOrderIndex(a.hub, orderByGlobalKey);
    final bIndex = _hubLibraryOrderIndex(b.hub, orderByGlobalKey);
    if (aIndex == null && bIndex == null) return a.index.compareTo(b.index);
    if (aIndex == null) return 1;
    if (bIndex == null) return -1;

    final order = aIndex.compareTo(bIndex);
    if (order != 0) return order;
    return a.index.compareTo(b.index);
  });

  var changed = false;
  for (var i = 0; i < hubs.length; i++) {
    final hub = indexedHubs[i].hub;
    if (!identical(hubs[i], hub)) changed = true;
    hubs[i] = hub;
  }
  return changed;
}

int? _hubLibraryOrderIndex(MediaHub hub, Map<String, int> orderByGlobalKey) {
  final hubLibraryKey = _globalKey(serverIdOrNull(hub.serverId), hub.libraryId);
  final hubIndex = hubLibraryKey == null ? null : orderByGlobalKey[hubLibraryKey];
  if (hubIndex != null) return hubIndex;

  int? bestIndex;
  for (final item in hub.items) {
    final key = _globalKey(serverIdOrNull(item.serverId ?? hub.serverId), item.libraryId);
    final index = key == null ? null : orderByGlobalKey[key];
    if (index != null && (bestIndex == null || index < bestIndex)) {
      bestIndex = index;
    }
  }
  return bestIndex;
}

String? _globalKey(ServerId? serverId, String? libraryId) {
  if (serverId == null || libraryId == null) return null;
  return buildGlobalKey(ServerId(serverId), libraryId);
}
