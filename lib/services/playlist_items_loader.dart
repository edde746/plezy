import '../media/media_item.dart';
import '../media/media_server_client.dart';

/// Page through every item in a playlist via the backend-neutral client API.
Future<List<MediaItem>> fetchAllPlaylistItems(MediaServerClient client, String playlistId, {int pageSize = 100}) async {
  final all = <MediaItem>[];
  var offset = 0;
  while (true) {
    final page = await client.fetchPlaylistPage(playlistId, start: offset, size: pageSize);
    if (page.items.isEmpty) break;
    all.addAll(page.items);
    if (all.length >= page.totalCount) break;
    offset += page.items.length;
  }
  return all;
}

/// Page through every item in a collection via the backend-neutral client API.
Future<List<MediaItem>> fetchAllCollectionItemsPaged(
  MediaServerClient client,
  String collectionId, {
  int pageSize = 100,
  String? libraryId,
  String? libraryTitle,
}) async {
  final all = <MediaItem>[];
  var offset = 0;
  while (true) {
    final page = await client.fetchCollectionPage(
      collectionId,
      start: offset,
      size: pageSize,
      libraryId: libraryId,
      libraryTitle: libraryTitle,
    );
    if (page.items.isEmpty) break;
    all.addAll(page.items);
    if (all.length >= page.totalCount || page.items.length < pageSize) break;
    offset += page.items.length;
  }
  return all;
}
