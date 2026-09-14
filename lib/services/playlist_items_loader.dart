import '../media/library_query.dart';
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
}) => drainPages<MediaItem>(
  (start, size) => client.fetchPlaylistPage(playlistId, start: start, size: size, abort: abort),
  pageSize: pageSize,
  abort: abort,
);

/// Page through every item in a collection via the backend-neutral client API.
Future<List<MediaItem>> fetchAllCollectionItemsPaged(
  MediaServerClient client,
  String collectionId, {
  int pageSize = 100,
  String? libraryId,
  String? libraryTitle,
}) => drainPages<MediaItem>(
  (start, size) => client.fetchCollectionPage(
    collectionId,
    start: start,
    size: size,
    libraryId: libraryId,
    libraryTitle: libraryTitle,
  ),
  pageSize: pageSize,
  stopOnShortPage: true,
);
