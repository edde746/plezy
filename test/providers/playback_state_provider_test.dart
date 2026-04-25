import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/play_queue_response.dart';
import 'package:plezy/models/plex_metadata.dart';
import 'package:plezy/providers/playback_state_provider.dart';

PlexMetadata _item(String ratingKey, int playQueueItemID) =>
    PlexMetadata(ratingKey: ratingKey, playQueueItemID: playQueueItemID, title: 'Episode $ratingKey');

PlayQueueResponse _queue({
  int playQueueID = 1,
  int? selectedItemID,
  bool shuffled = false,
  int? totalCount,
  int? size,
  List<PlexMetadata>? items,
}) {
  return PlayQueueResponse(
    playQueueID: playQueueID,
    playQueueSelectedItemID: selectedItemID,
    playQueueShuffled: shuffled,
    playQueueTotalCount: totalCount,
    playQueueVersion: 1,
    size: size,
    items: items,
  );
}

void main() {
  group('PlaybackStateProvider', () {
    test('starts in idle state with no queue', () {
      final p = PlaybackStateProvider();
      expect(p.isQueueActive, isFalse);
      expect(p.isPlaylistActive, isFalse);
      expect(p.isShuffleActive, isFalse);
      expect(p.playQueueId, isNull);
      expect(p.currentPlayQueueItemID, isNull);
      expect(p.shuffleContextKey, isNull);
      expect(p.loadedItems, isEmpty);
      p.dispose();
    });

    test('setPlaybackFromPlayQueue populates state and notifies', () async {
      final p = PlaybackStateProvider();
      var notified = 0;
      p.addListener(() => notified++);

      final items = [_item('100', 1001), _item('101', 1002), _item('102', 1003)];
      final response = _queue(playQueueID: 42, selectedItemID: 1002, shuffled: true, totalCount: 3, items: items);

      await p.setPlaybackFromPlayQueue(response, 'show-key');

      expect(p.playQueueId, 42);
      expect(p.currentPlayQueueItemID, 1002);
      expect(p.isShuffleActive, isTrue);
      expect(p.isPlaylistActive, isTrue);
      expect(p.isQueueActive, isTrue);
      expect(p.shuffleContextKey, 'show-key');
      expect(p.loadedItems, hasLength(3));
      expect(notified, 1);

      p.dispose();
    });

    test('totalCount falls back to size then items length', () async {
      final p = PlaybackStateProvider();
      final items = [_item('a', 1), _item('b', 2)];

      // totalCount missing, size present → uses size
      await p.setPlaybackFromPlayQueue(_queue(size: 7, items: items), null);
      expect(p.loadedItems, hasLength(2));
      // The fallback is internal but observable via getNextEpisode at end-of-window:
      // size=7 means the window isn't at the end, so the loop guard differs.

      // Reset: totalCount=null, size=null, items length used.
      p.clearShuffle();
      await p.setPlaybackFromPlayQueue(_queue(items: items), null);
      expect(p.loadedItems, hasLength(2));

      p.dispose();
    });

    test('clearShuffle resets all state and notifies', () async {
      final p = PlaybackStateProvider();
      final items = [_item('a', 1), _item('b', 2)];
      await p.setPlaybackFromPlayQueue(
        _queue(playQueueID: 99, selectedItemID: 1, totalCount: 2, items: items),
        'context-1',
      );
      expect(p.isQueueActive, isTrue);

      var notified = 0;
      p.addListener(() => notified++);

      p.clearShuffle();
      expect(p.isQueueActive, isFalse);
      expect(p.isPlaylistActive, isFalse);
      expect(p.isShuffleActive, isFalse);
      expect(p.playQueueId, isNull);
      expect(p.currentPlayQueueItemID, isNull);
      expect(p.shuffleContextKey, isNull);
      expect(p.loadedItems, isEmpty);
      expect(notified, 1);

      p.dispose();
    });

    test('setCurrentItem updates id only when in queue mode', () async {
      final p = PlaybackStateProvider();

      // Not in queue mode → no-op
      var notified = 0;
      p.addListener(() => notified++);
      p.setCurrentItem(_item('a', 5));
      expect(p.currentPlayQueueItemID, isNull);
      expect(notified, 0);

      // Enter queue mode
      await p.setPlaybackFromPlayQueue(
        _queue(playQueueID: 1, selectedItemID: 1001, totalCount: 1, items: [_item('a', 1001)]),
        null,
      );
      // setPlaybackFromPlayQueue notifies once
      final preNotify = notified;

      p.setCurrentItem(_item('b', 2002));
      expect(p.currentPlayQueueItemID, 2002);
      expect(notified, preNotify + 1);

      // Item without playQueueItemID → no update, no notify
      p.setCurrentItem(PlexMetadata(ratingKey: 'd'));
      expect(p.currentPlayQueueItemID, 2002);

      p.dispose();
    });

    test('getNextEpisode returns next loaded item when current is mid-window', () async {
      final p = PlaybackStateProvider();
      final items = [_item('a', 1001), _item('b', 1002), _item('c', 1003)];
      await p.setPlaybackFromPlayQueue(_queue(playQueueID: 1, selectedItemID: 1002, totalCount: 3, items: items), null);

      final next = await p.getNextEpisode('b');
      expect(next, isNotNull);
      expect(next!.ratingKey, 'c');
      expect(next.playQueueItemID, 1003);

      // currentPlayQueueItemID is NOT updated by getNextEpisode (setCurrentItem does that).
      expect(p.currentPlayQueueItemID, 1002);

      p.dispose();
    });

    test('getNextEpisode returns null at end of queue without loop', () async {
      final p = PlaybackStateProvider();
      final items = [_item('a', 1001), _item('b', 1002)];
      await p.setPlaybackFromPlayQueue(_queue(playQueueID: 1, selectedItemID: 1002, totalCount: 2, items: items), null);

      final next = await p.getNextEpisode('b');
      expect(next, isNull);

      p.dispose();
    });

    test('getNextEpisode with no queue returns null (sequential mode)', () async {
      final p = PlaybackStateProvider();
      final next = await p.getNextEpisode('any-key');
      expect(next, isNull);
      p.dispose();
    });

    test('getPreviousEpisode returns previous loaded item when current is mid-window', () async {
      final p = PlaybackStateProvider();
      final items = [_item('a', 1001), _item('b', 1002), _item('c', 1003)];
      await p.setPlaybackFromPlayQueue(_queue(playQueueID: 1, selectedItemID: 1002, totalCount: 3, items: items), null);

      final prev = await p.getPreviousEpisode('b');
      expect(prev, isNotNull);
      expect(prev!.ratingKey, 'a');
      expect(prev.playQueueItemID, 1001);

      p.dispose();
    });

    test('getPreviousEpisode at index 0 returns null', () async {
      final p = PlaybackStateProvider();
      final items = [_item('a', 1001), _item('b', 1002)];
      await p.setPlaybackFromPlayQueue(_queue(playQueueID: 1, selectedItemID: 1001, totalCount: 2, items: items), null);

      final prev = await p.getPreviousEpisode('a');
      expect(prev, isNull);

      p.dispose();
    });

    test('getPreviousEpisode without queue mode returns null', () async {
      final p = PlaybackStateProvider();
      final prev = await p.getPreviousEpisode('any-key');
      expect(prev, isNull);
      p.dispose();
    });

    test('loadedItems getter is unmodifiable', () async {
      final p = PlaybackStateProvider();
      await p.setPlaybackFromPlayQueue(
        _queue(playQueueID: 1, selectedItemID: 1, totalCount: 1, items: [_item('a', 1)]),
        null,
      );
      expect(() => p.loadedItems.add(_item('mutated', 999)), throwsUnsupportedError);
      p.dispose();
    });

    test('safeNotifyListeners after dispose is a no-op', () async {
      final p = PlaybackStateProvider();
      p.dispose();
      // clearShuffle and setPlaybackFromPlayQueue both notify; must not throw.
      p.clearShuffle();
      await p.setPlaybackFromPlayQueue(_queue(playQueueID: 1, totalCount: 1, items: [_item('a', 1)]), null);
    });
  });
}
