import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/models/download_models.dart';
import 'package:plezy/utils/downloaded_version_match.dart';

DownloadedMediaItem _row({int mediaIndex = 0, String? mediaSourceId}) {
  return DownloadedMediaItem(
    id: 1,
    serverId: 'srv',
    ratingKey: 'movie-1',
    globalKey: 'srv:movie-1',
    type: 'movie',
    status: DownloadStatus.completed.index,
    progress: 100,
    downloadedBytes: 0,
    retryCount: 0,
    mediaIndex: mediaIndex,
    mediaSourceId: mediaSourceId,
  );
}

void main() {
  group('downloadedVersionMatches', () {
    test('source id wins when both sides have one', () {
      // Equal ids match even when the index disagrees (Jellyfin merged
      // versions reorder between fetches).
      expect(
        downloadedVersionMatches(
          _row(mediaIndex: 1, mediaSourceId: 'src-a'),
          requestedMediaIndex: 0,
          requestedMediaSourceId: 'src-a',
        ),
        isTrue,
      );
      // Different ids reject even when the index agrees.
      expect(
        downloadedVersionMatches(
          _row(mediaIndex: 0, mediaSourceId: 'src-a'),
          requestedMediaIndex: 0,
          requestedMediaSourceId: 'src-b',
        ),
        isFalse,
      );
    });

    test('falls back to index when either side lacks a source id', () {
      // Legacy pre-v15 row: NULL source id.
      expect(
        downloadedVersionMatches(_row(mediaIndex: 0), requestedMediaIndex: 0, requestedMediaSourceId: 'src-a'),
        isTrue,
      );
      expect(
        downloadedVersionMatches(_row(mediaIndex: 1), requestedMediaIndex: 0, requestedMediaSourceId: 'src-a'),
        isFalse,
      );
      // Caller without a source id.
      expect(downloadedVersionMatches(_row(mediaIndex: 1, mediaSourceId: 'src-a'), requestedMediaIndex: 1), isTrue);
      expect(downloadedVersionMatches(_row(mediaIndex: 1, mediaSourceId: 'src-a'), requestedMediaIndex: 0), isFalse);
    });

    test('blank requested source id is treated as absent', () {
      expect(
        downloadedVersionMatches(
          _row(mediaIndex: 0, mediaSourceId: 'src-a'),
          requestedMediaIndex: 0,
          requestedMediaSourceId: '  ',
        ),
        isTrue,
      );
    });

    test('null requested index means any version', () {
      expect(downloadedVersionMatches(_row(mediaIndex: 1, mediaSourceId: 'src-a')), isTrue);
      expect(downloadedVersionMatches(_row(mediaIndex: 1)), isTrue);
      // But a source-id mismatch still rejects.
      expect(
        downloadedVersionMatches(_row(mediaIndex: 1, mediaSourceId: 'src-a'), requestedMediaSourceId: 'src-b'),
        isFalse,
      );
    });
  });
}
