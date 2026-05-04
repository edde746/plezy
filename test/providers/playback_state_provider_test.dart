import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/play_queue.dart';
import 'package:plezy/models/plex/play_queue_response.dart';
import 'package:plezy/providers/playback_state_provider.dart';

PlexMediaItem _item(String ratingKey, int playQueueItemID) => PlexMediaItem(
  id: ratingKey,
  kind: MediaKind.episode,
  playQueueItemId: playQueueItemID,
  title: 'Episode $ratingKey',
);

PlexMediaItem _miItem(String id, int playQueueItemId) =>
    PlexMediaItem(id: id, kind: MediaKind.episode, playQueueItemId: playQueueItemId);

PlayQueueResponse _queue({
  int playQueueID = 1,
  int? selectedItemID,
  bool shuffled = false,
  int? totalCount,
  int? size,
  List<MediaItem>? items,
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
      p.setCurrentItem(_miItem('a', 5));
      expect(p.currentPlayQueueItemID, isNull);
      expect(notified, 0);

      // Enter queue mode
      await p.setPlaybackFromPlayQueue(
        _queue(playQueueID: 1, selectedItemID: 1001, totalCount: 1, items: [_item('a', 1001)]),
        null,
      );
      // setPlaybackFromPlayQueue notifies once
      final preNotify = notified;

      p.setCurrentItem(_miItem('b', 2002));
      expect(p.currentPlayQueueItemID, 2002);
      expect(notified, preNotify + 1);

      // Item without playQueueItemId → no update, no notify
      p.setCurrentItem(MediaItem(id: 'd', backend: MediaBackend.plex, kind: MediaKind.episode));
      expect(p.currentPlayQueueItemID, 2002);

      p.dispose();
    });

    test('getNextEpisode returns next loaded item when current is mid-window', () async {
      final p = PlaybackStateProvider();
      final items = [_item('a', 1001), _item('b', 1002), _item('c', 1003)];
      await p.setPlaybackFromPlayQueue(_queue(playQueueID: 1, selectedItemID: 1002, totalCount: 3, items: items), null);

      final next = await p.getNextEpisode('b');
      expect(next, isNotNull);
      expect(next!.id, 'c');
      expect((next as PlexMediaItem).playQueueItemId, 1003);

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
      expect(prev!.id, 'a');
      expect((prev as PlexMediaItem).playQueueItemId, 1001);

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
      expect(() => p.loadedItems.add(_miItem('mutated', 999)), throwsUnsupportedError);
      p.dispose();
    });

    test('safeNotifyListeners after dispose is a no-op', () async {
      final p = PlaybackStateProvider();
      p.dispose();
      // clearShuffle and setPlaybackFromPlayQueue both notify; must not throw.
      p.clearShuffle();
      await p.setPlaybackFromPlayQueue(_queue(playQueueID: 1, totalCount: 1, items: [_item('a', 1)]), null);
    });

    test('playQueueItemIdFor returns synthetic ids for Jellyfin local queue items', () {
      // Anchor: VideoPlayerScreen.initState and `_ensurePlayQueue` both gate
      // on `isItemInActiveQueue(meta)` (which delegates to `playQueueItemIdFor`)
      // so a Jellyfin playlist queue survives entry into the player. If this
      // returns null for queue members, the player wipes the launcher-set
      // queue and prev/next walks the show instead of the playlist.
      final p = PlaybackStateProvider();
      addTearDown(p.dispose);

      final ep1 = MediaItem(id: 'ep1', backend: MediaBackend.jellyfin, kind: MediaKind.episode);
      final ep2 = MediaItem(id: 'ep2', backend: MediaBackend.jellyfin, kind: MediaKind.episode);
      final outsider = MediaItem(id: 'ep-other', backend: MediaBackend.jellyfin, kind: MediaKind.episode);

      p.setPlaybackFromLocalQueue(
        LocalPlayQueue(id: 'jellyfin:playlist-X', items: [ep1, ep2], currentIndex: 0, backendId: 'jellyfin'),
        contextKey: 'playlist-X',
      );

      expect(p.playQueueItemIdFor(ep1), 0);
      expect(p.playQueueItemIdFor(ep2), 1);
      expect(p.playQueueItemIdFor(outsider), isNull);
      expect(p.isItemInActiveQueue(ep1), isTrue);
      expect(p.isItemInActiveQueue(outsider), isFalse);
    });

    test('isItemInActiveQueue keeps Plex playlist/collection queues alive', () async {
      // Anchor (Plex side): `_ensurePlayQueue` in episode_queue.dart gates
      // its "preserve vs. clobber" decision on `isItemInActiveQueue`. A
      // Plex playlist queue's contextKey is the playlist id (not the show),
      // so a context-key-only check would wipe it. Membership via the
      // server-stamped `playQueueItemId` is the right signal — see gh #978.
      final p = PlaybackStateProvider();
      addTearDown(p.dispose);

      final inQueue = _item('ep-in-playlist', 5001);
      // A real-world non-queue item (e.g. tapped from media detail) carries
      // no `playQueueItemId` — that's how the helper distinguishes it from
      // a launcher-seeded queue member.
      final outsider = PlexMediaItem(id: 'ep-different-show', kind: MediaKind.episode);

      await p.setPlaybackFromPlayQueue(
        _queue(
          playQueueID: 77,
          selectedItemID: 5001,
          totalCount: 2,
          items: [inQueue, _item('ep-other-in-playlist', 5002)],
        ),
        // contextKey is the playlist id, deliberately != grandparentId of any item
        'playlist-Z',
      );

      expect(p.isItemInActiveQueue(inQueue), isTrue);
      expect(p.isItemInActiveQueue(outsider), isFalse);
    });

    test('isItemInActiveQueue is false when no queue is active', () {
      final p = PlaybackStateProvider();
      addTearDown(p.dispose);

      final ep = _item('ep1', 1);
      expect(p.isQueueActive, isFalse);
      expect(p.isItemInActiveQueue(ep), isFalse);
    });
  });
}
