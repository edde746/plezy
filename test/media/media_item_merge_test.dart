import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_item_merge.dart';
import 'package:plezy/media/media_kind.dart';
import '../test_helpers/media_items.dart';

void main() {
  MediaItem item({String? serverId, String? serverName, String? libraryId, String? libraryTitle}) => testMediaItem(
    id: 'item',
    backend: MediaBackend.plex,
    kind: MediaKind.movie,
    serverId: serverId,
    serverName: serverName,
    libraryId: libraryId,
    libraryTitle: libraryTitle,
  );

  test('uses the authoritative fallback when both items omit server identity', () {
    final merged = mergeFetchedMediaItem(fetched: item(), fallbackServerId: ServerId('fallback'));

    expect(merged.serverId, 'fallback');
    expect(merged.globalKey, 'fallback:item');
  });

  test('preserves existing identity while preferring fetched library context', () {
    final merged = mergeFetchedMediaItem(
      fetched: item(serverId: 'fetched', serverName: 'Fetched', libraryId: 'new-lib', libraryTitle: 'New'),
      existing: item(serverId: 'existing', serverName: 'Existing', libraryId: 'old-lib', libraryTitle: 'Old'),
      fallbackServerId: ServerId('fallback'),
    );

    expect(merged.serverId, 'existing');
    expect(merged.serverName, 'Existing');
    expect(merged.libraryId, 'new-lib');
    expect(merged.libraryTitle, 'New');
  });

  test('fills missing fetched library context from the existing item', () {
    final merged = mergeFetchedMediaItem(
      fetched: item(),
      existing: item(libraryId: 'old-lib', libraryTitle: 'Old'),
      fallbackServerId: ServerId('fallback'),
    );

    expect(merged.libraryId, 'old-lib');
    expect(merged.libraryTitle, 'Old');
  });
}
