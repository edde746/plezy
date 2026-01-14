import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/models/plex_metadata.dart';
import 'package:plezy/models/play_queue_response.dart';

void main() {
  group('PlaybackMode enum', () {
    test('has playQueue value', () {
      expect(PlaybackMode.playQueue, isNotNull);
      expect(PlaybackMode.playQueue.name, 'playQueue');
    });

    test('values list contains all modes', () {
      expect(PlaybackMode.values, contains(PlaybackMode.playQueue));
      expect(PlaybackMode.values.length, 1);
    });
  });

  group('PlaybackStateProvider', () {
    late PlaybackStateProvider provider;

    setUp(() {
      provider = PlaybackStateProvider();
    });

    group('initial state', () {
      test('starts with null playback mode', () {
        expect(provider.playbackMode, isNull);
      });

      test('starts with shuffle inactive', () {
        expect(provider.isShuffleActive, false);
      });

      test('starts with playlist inactive', () {
        expect(provider.isPlaylistActive, false);
      });

      test('starts with queue inactive', () {
        expect(provider.isQueueActive, false);
      });

      test('starts with null shuffle context key', () {
        expect(provider.shuffleContextKey, isNull);
      });

      test('starts with null play queue ID', () {
        expect(provider.playQueueId, isNull);
      });

      test('starts with zero queue length', () {
        expect(provider.queueLength, 0);
      });

      test('starts with zero current position', () {
        expect(provider.currentPosition, 0);
      });
    });

    group('setPlaybackFromPlayQueue', () {
      test('sets play queue ID', () async {
        final playQueue = PlayQueueResponse(
          playQueueID: 12345,
          playQueueVersion: 1,
          playQueueTotalCount: 10,
          playQueueShuffled: false,
          playQueueSelectedItemID: 1,
          items: [],
        );

        await provider.setPlaybackFromPlayQueue(playQueue, 'context-key');

        expect(provider.playQueueId, 12345);
      });

      test('sets total count from playQueueTotalCount', () async {
        final playQueue = PlayQueueResponse(
          playQueueID: 12345,
          playQueueVersion: 1,
          playQueueTotalCount: 25,
          playQueueShuffled: false,
          playQueueSelectedItemID: 1,
          items: [],
        );

        await provider.setPlaybackFromPlayQueue(playQueue, 'context-key');

        expect(provider.queueLength, 25);
      });

      test('uses size as fallback when totalCount is null', () async {
        final playQueue = PlayQueueResponse(
          playQueueID: 12345,
          playQueueVersion: 1,
          playQueueTotalCount: null,
          size: 15,
          playQueueShuffled: false,
          playQueueSelectedItemID: 1,
          items: [],
        );

        await provider.setPlaybackFromPlayQueue(playQueue, 'context-key');

        expect(provider.queueLength, 15);
      });

      test('uses items length as fallback when size is null', () async {
        final items = [
          _createTestMetadata(playQueueItemID: 1),
          _createTestMetadata(playQueueItemID: 2),
          _createTestMetadata(playQueueItemID: 3),
        ];

        final playQueue = PlayQueueResponse(
          playQueueID: 12345,
          playQueueVersion: 1,
          playQueueTotalCount: null,
          size: null,
          playQueueShuffled: false,
          playQueueSelectedItemID: 1,
          items: items,
        );

        await provider.setPlaybackFromPlayQueue(playQueue, 'context-key');

        expect(provider.queueLength, 3);
      });

      test('sets shuffled state when true', () async {
        final playQueue = PlayQueueResponse(
          playQueueID: 12345,
          playQueueVersion: 1,
          playQueueTotalCount: 10,
          playQueueShuffled: true,
          playQueueSelectedItemID: 1,
          items: [],
        );

        await provider.setPlaybackFromPlayQueue(playQueue, 'context-key');

        expect(provider.isShuffleActive, true);
      });

      test('sets shuffled state when false', () async {
        final playQueue = PlayQueueResponse(
          playQueueID: 12345,
          playQueueVersion: 1,
          playQueueTotalCount: 10,
          playQueueShuffled: false,
          playQueueSelectedItemID: 1,
          items: [],
        );

        await provider.setPlaybackFromPlayQueue(playQueue, 'context-key');

        expect(provider.isShuffleActive, false);
      });

      test('sets context key', () async {
        final playQueue = PlayQueueResponse(
          playQueueID: 12345,
          playQueueVersion: 1,
          playQueueTotalCount: 10,
          playQueueShuffled: false,
          playQueueSelectedItemID: 1,
          items: [],
        );

        await provider.setPlaybackFromPlayQueue(playQueue, 'my-context-key');

        expect(provider.shuffleContextKey, 'my-context-key');
      });

      test('sets playback mode to playQueue', () async {
        final playQueue = PlayQueueResponse(
          playQueueID: 12345,
          playQueueVersion: 1,
          playQueueTotalCount: 10,
          playQueueShuffled: false,
          playQueueSelectedItemID: 1,
          items: [],
        );

        await provider.setPlaybackFromPlayQueue(playQueue, 'context-key');

        expect(provider.playbackMode, PlaybackMode.playQueue);
        expect(provider.isPlaylistActive, true);
        expect(provider.isQueueActive, true);
      });

      test('notifies listeners', () async {
        var notified = false;
        provider.addListener(() => notified = true);

        final playQueue = PlayQueueResponse(
          playQueueID: 12345,
          playQueueVersion: 1,
          playQueueTotalCount: 10,
          playQueueShuffled: false,
          playQueueSelectedItemID: 1,
          items: [],
        );

        await provider.setPlaybackFromPlayQueue(playQueue, 'context-key');

        expect(notified, true);
      });
    });

    group('setCurrentItem', () {
      test('updates current item when in play queue mode', () async {
        final items = [
          _createTestMetadata(ratingKey: '1', playQueueItemID: 100),
          _createTestMetadata(ratingKey: '2', playQueueItemID: 101),
        ];

        final playQueue = PlayQueueResponse(
          playQueueID: 12345,
          playQueueVersion: 1,
          playQueueTotalCount: 2,
          playQueueShuffled: false,
          playQueueSelectedItemID: 100,
          items: items,
        );

        await provider.setPlaybackFromPlayQueue(playQueue, 'context-key');
        expect(provider.currentPosition, 1);

        provider.setCurrentItem(items[1]);
        expect(provider.currentPosition, 2);
      });

      test('does nothing when not in play queue mode', () {
        final metadata = _createTestMetadata(playQueueItemID: 100);
        provider.setCurrentItem(metadata);
        // Should not crash or change state
        expect(provider.playbackMode, isNull);
      });

      test('does nothing when metadata has no playQueueItemID', () async {
        final playQueue = PlayQueueResponse(
          playQueueID: 12345,
          playQueueVersion: 1,
          playQueueTotalCount: 2,
          playQueueShuffled: false,
          playQueueSelectedItemID: 100,
          items: [],
        );

        await provider.setPlaybackFromPlayQueue(playQueue, 'context-key');

        final metadata = _createTestMetadata(playQueueItemID: null);
        provider.setCurrentItem(metadata);
        // Should not crash
      });

      test('notifies listeners', () async {
        var notifyCount = 0;
        provider.addListener(() => notifyCount++);

        final items = [
          _createTestMetadata(ratingKey: '1', playQueueItemID: 100),
        ];

        final playQueue = PlayQueueResponse(
          playQueueID: 12345,
          playQueueVersion: 1,
          playQueueTotalCount: 1,
          playQueueShuffled: false,
          playQueueSelectedItemID: 100,
          items: items,
        );

        await provider.setPlaybackFromPlayQueue(playQueue, 'context-key');
        final countAfterSetup = notifyCount;

        provider.setCurrentItem(items[0]);
        expect(notifyCount, greaterThan(countAfterSetup));
      });
    });

    group('currentPosition', () {
      test('returns 0 when no items loaded', () async {
        final playQueue = PlayQueueResponse(
          playQueueID: 12345,
          playQueueVersion: 1,
          playQueueTotalCount: 10,
          playQueueShuffled: false,
          playQueueSelectedItemID: 1,
          items: [],
        );

        await provider.setPlaybackFromPlayQueue(playQueue, 'context-key');

        expect(provider.currentPosition, 0);
      });

      test('returns correct position when item is found', () async {
        final items = [
          _createTestMetadata(ratingKey: '1', playQueueItemID: 100),
          _createTestMetadata(ratingKey: '2', playQueueItemID: 101),
          _createTestMetadata(ratingKey: '3', playQueueItemID: 102),
        ];

        final playQueue = PlayQueueResponse(
          playQueueID: 12345,
          playQueueVersion: 1,
          playQueueTotalCount: 3,
          playQueueShuffled: false,
          playQueueSelectedItemID: 101, // Select second item
          items: items,
        );

        await provider.setPlaybackFromPlayQueue(playQueue, 'context-key');

        expect(provider.currentPosition, 2); // 1-indexed
      });

      test('returns 0 when current item not in loaded items', () async {
        final items = [
          _createTestMetadata(ratingKey: '1', playQueueItemID: 100),
          _createTestMetadata(ratingKey: '2', playQueueItemID: 101),
        ];

        final playQueue = PlayQueueResponse(
          playQueueID: 12345,
          playQueueVersion: 1,
          playQueueTotalCount: 10,
          playQueueShuffled: false,
          playQueueSelectedItemID: 999, // Not in items
          items: items,
        );

        await provider.setPlaybackFromPlayQueue(playQueue, 'context-key');

        expect(provider.currentPosition, 0);
      });
    });

    group('clearShuffle', () {
      test('resets all state', () async {
        final items = [
          _createTestMetadata(ratingKey: '1', playQueueItemID: 100),
        ];

        final playQueue = PlayQueueResponse(
          playQueueID: 12345,
          playQueueVersion: 1,
          playQueueTotalCount: 10,
          playQueueShuffled: true,
          playQueueSelectedItemID: 100,
          items: items,
        );

        await provider.setPlaybackFromPlayQueue(playQueue, 'context-key');

        // Verify state is set
        expect(provider.playQueueId, 12345);
        expect(provider.isShuffleActive, true);
        expect(provider.queueLength, 10);

        // Clear
        provider.clearShuffle();

        // Verify state is reset
        expect(provider.playQueueId, isNull);
        expect(provider.isShuffleActive, false);
        expect(provider.queueLength, 0);
        expect(provider.shuffleContextKey, isNull);
        expect(provider.playbackMode, isNull);
        expect(provider.isPlaylistActive, false);
        expect(provider.isQueueActive, false);
        expect(provider.currentPosition, 0);
      });

      test('notifies listeners', () async {
        final playQueue = PlayQueueResponse(
          playQueueID: 12345,
          playQueueVersion: 1,
          playQueueTotalCount: 10,
          playQueueShuffled: false,
          playQueueSelectedItemID: 1,
          items: [],
        );

        await provider.setPlaybackFromPlayQueue(playQueue, 'context-key');

        var notified = false;
        provider.addListener(() => notified = true);

        provider.clearShuffle();

        expect(notified, true);
      });
    });

    group('getNextEpisode', () {
      test('returns null when not in play queue mode', () async {
        final result = await provider.getNextEpisode('current-key');
        expect(result, isNull);
      });

      test('returns next item in queue', () async {
        final items = [
          _createTestMetadata(ratingKey: '1', playQueueItemID: 100),
          _createTestMetadata(ratingKey: '2', playQueueItemID: 101),
          _createTestMetadata(ratingKey: '3', playQueueItemID: 102),
        ];

        final playQueue = PlayQueueResponse(
          playQueueID: 12345,
          playQueueVersion: 1,
          playQueueTotalCount: 3,
          playQueueShuffled: false,
          playQueueSelectedItemID: 100, // First item
          items: items,
        );

        await provider.setPlaybackFromPlayQueue(playQueue, 'context-key');

        final nextItem = await provider.getNextEpisode('1');
        expect(nextItem, isNotNull);
        expect(nextItem!.ratingKey, '2');
      });

      test('returns null at end of queue without loop', () async {
        final items = [
          _createTestMetadata(ratingKey: '1', playQueueItemID: 100),
          _createTestMetadata(ratingKey: '2', playQueueItemID: 101),
        ];

        final playQueue = PlayQueueResponse(
          playQueueID: 12345,
          playQueueVersion: 1,
          playQueueTotalCount: 2,
          playQueueShuffled: false,
          playQueueSelectedItemID: 101, // Last item
          items: items,
        );

        await provider.setPlaybackFromPlayQueue(playQueue, 'context-key');

        final nextItem = await provider.getNextEpisode('2', loopQueue: false);
        expect(nextItem, isNull);
      });
    });

    group('getPreviousEpisode', () {
      test('returns null when not in play queue mode', () async {
        final result = await provider.getPreviousEpisode('current-key');
        expect(result, isNull);
      });

      test('returns previous item in queue', () async {
        final items = [
          _createTestMetadata(ratingKey: '1', playQueueItemID: 100),
          _createTestMetadata(ratingKey: '2', playQueueItemID: 101),
          _createTestMetadata(ratingKey: '3', playQueueItemID: 102),
        ];

        final playQueue = PlayQueueResponse(
          playQueueID: 12345,
          playQueueVersion: 1,
          playQueueTotalCount: 3,
          playQueueShuffled: false,
          playQueueSelectedItemID: 101, // Second item
          items: items,
        );

        await provider.setPlaybackFromPlayQueue(playQueue, 'context-key');

        final prevItem = await provider.getPreviousEpisode('2');
        expect(prevItem, isNotNull);
        expect(prevItem!.ratingKey, '1');
      });

      test('returns null at beginning of queue', () async {
        final items = [
          _createTestMetadata(ratingKey: '1', playQueueItemID: 100),
          _createTestMetadata(ratingKey: '2', playQueueItemID: 101),
        ];

        final playQueue = PlayQueueResponse(
          playQueueID: 12345,
          playQueueVersion: 1,
          playQueueTotalCount: 2,
          playQueueShuffled: false,
          playQueueSelectedItemID: 100, // First item
          items: items,
        );

        await provider.setPlaybackFromPlayQueue(playQueue, 'context-key');

        final prevItem = await provider.getPreviousEpisode('1');
        expect(prevItem, isNull);
      });
    });
  });
}

/// Helper to create test PlexMetadata
PlexMetadata _createTestMetadata({
  String ratingKey = '12345',
  String key = '/library/metadata/12345',
  String type = 'episode',
  String title = 'Test Episode',
  int? playQueueItemID,
}) {
  return PlexMetadata(
    ratingKey: ratingKey,
    key: key,
    type: type,
    title: title,
    playQueueItemID: playQueueItemID,
  );
}
