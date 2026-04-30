import '../media/media_item.dart';
import '../media/media_server_client.dart';

/// Page through every item in a playlist via the backend-neutral client API.
Future<List<MediaItem>> fetchAllPlaylistItems(MediaServerClient client, String playlistId, {int pageSize = 100}) async {
  final all = <MediaItem>[];
  var offset = 0;
  while (true) {
    final page = await client.fetchPlaylistItems(playlistId, offset: offset, limit: pageSize);
    if (page.isEmpty) break;
    all.addAll(page);
    if (page.length < pageSize) break;
    offset += page.length;
  }
  return all;
}
