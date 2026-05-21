import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/models/trakt/trakt_ids.dart';
import 'package:vibe_stream/services/trakt/trakt_constants.dart';
import 'package:vibe_stream/services/trakt/trakt_sync_queue.dart';

void main() {
  test('TraktSyncQueueItem preserves library context in JSON', () {
    const item = TraktSyncQueueItem(
      op: TraktSyncOp.add,
      ratingKey: 'episode-1',
      serverId: 'server-1',
      libraryGlobalKey: 'server-1:7',
      kind: TraktMediaKind.episode,
      ids: TraktIds(tvdb: 123),
      watchedAtIso: '2026-05-12T00:00:00.000Z',
      season: 1,
      number: 2,
    );

    final decoded = TraktSyncQueueItem.fromJson(item.toJson());

    expect(decoded.libraryGlobalKey, 'server-1:7');
    expect(decoded.incrementAttempts().libraryGlobalKey, 'server-1:7');
  });
}
