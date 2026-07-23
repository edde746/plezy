import '../media/media_item.dart';
import '../media/media_server_client.dart';
import '../utils/media_server_http_client.dart';

const int playlistItemsPageSize = 200;

/// Page through every item in a playlist via the backend-neutral client API.
Future<List<MediaItem>> fetchAllPlaylistItems(
  MediaServerClient client,
  String playlistId, {
  int pageSize = playlistItemsPageSize,
  AbortController? abort,
}) async {
  final all = <MediaItem>[];
  var offset = 0;
  while (true) {
    abort?.throwIfAborted();
    final page = await client.fetchPlaylistPage(playlistId, start: offset, size: pageSize, abort: abort);
    abort?.throwIfAborted();
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
