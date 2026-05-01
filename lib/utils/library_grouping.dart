import '../media/media_library.dart';

typedef LibraryServerGroups = ({List<String> serverOrder, Map<String, List<MediaLibrary>> byServer});

/// Groups libraries by server while preserving each server's first appearance in
/// the provided list. Libraries without a server id are placed in the empty-key
/// bucket at their first occurrence.
LibraryServerGroups groupLibrariesByFirstAppearance(List<MediaLibrary> libraries) {
  final order = <String>[];
  final byServer = <String, List<MediaLibrary>>{};
  for (final lib in libraries) {
    final key = lib.serverId ?? '';
    if (!byServer.containsKey(key)) {
      order.add(key);
      byServer[key] = [];
    }
    byServer[key]!.add(lib);
  }
  return (serverOrder: order, byServer: byServer);
}
