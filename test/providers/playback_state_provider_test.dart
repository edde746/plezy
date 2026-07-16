import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_part.dart';
import 'package:plezy/media/media_version.dart';
import 'package:plezy/media/play_queue.dart';
import 'package:plezy/models/plex/play_queue_response.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import '../test_helpers/media_items.dart';

PlexMediaItem _item(String ratingKey, int playQueueItemID) => PlexMediaItem(
  id: ratingKey,
  kind: MediaKind.episode,
  playQueueItemId: playQueueItemID,
  title: 'Episode $ratingKey',
);

/// Episode queue entry carrying file identity, as Plex play-queue items do.
/// Episodes of a multi-episode file (`S02E24-E25.mkv`) get *distinct* part
/// ids (`part-<ratingKey>` here, mirroring real servers) but share [file].
PlexMediaItem _itemWithFile(String ratingKey, int playQueueItemID, String file) => PlexMediaItem(
  id: ratingKey,
  kind: MediaKind.episode,
  playQueueItemId: playQueueItemID,
  title: 'Episode $ratingKey',
  mediaVersions: [
    MediaVersion(
      id: 'v-$ratingKey',
      parts: [MediaPart(id: 'part-$ratingKey', file: file)],
    ),
  ],
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
      p.setCurrentItem(testMediaItem(id: 'd', backend: MediaBackend.plex, kind: MediaKind.episode));
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

    test('getNextEpisode does not retry recursively when loaded window misses target', () async {
      final p = PlaybackStateProvider();
      addTearDown(p.dispose);
      final items = [_item('a', 1001), _item('b', 1002)];
      await p.setPlaybackFromPlayQueue(_queue(playQueueID: 1, selectedItemID: 1002, totalCount: 3, items: items), null);

      var fetchCount = 0;
      p.setPlayQueueWindowFetcher((playQueueId, {center, window = 50}) async {
        fetchCount++;
        return _queue(playQueueID: playQueueId, selectedItemID: 1002, totalCount: 3, items: items);
      });

      expect(await p.getNextEpisode('b'), isNull);
      expect(fetchCount, 1);
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

      final ep1 = testMediaItem(id: 'ep1', backend: MediaBackend.jellyfin, kind: MediaKind.episode);
      final ep2 = testMediaItem(id: 'ep2', backend: MediaBackend.jellyfin, kind: MediaKind.episode);
      final outsider = testMediaItem(id: 'ep-other', backend: MediaBackend.jellyfin, kind: MediaKind.episode);

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

  group('multi-episode files (#1500)', () {
    // Plex lists each episode of a multi-episode file (S02E24-E25.mkv) as
    // its own queue entry with a distinct ratingKey AND a distinct part id,
    // but the same Part.file. e24/e25 share a file; e23 and e26 don't.
    const fileA = '/tv/S02E24-E25.mkv';
    Future<PlaybackStateProvider> queueWithMultiEpisodeFile({int selectedItemID = 1002}) async {
      final p = PlaybackStateProvider();
      final items = [
        _itemWithFile('e23', 1001, '/tv/S02E23.mkv'),
        _itemWithFile('e24', 1002, fileA),
        _itemWithFile('e25', 1003, fileA),
        _itemWithFile('e26', 1004, '/tv/S02E26-E27.mkv'),
      ];
      await p.setPlaybackFromPlayQueue(
        _queue(playQueueID: 1, selectedItemID: selectedItemID, totalCount: 4, items: items),
        null,
      );
      return p;
    }

    test('getNextEpisode skips the same-file sibling using playedPartId', () async {
      final p = await queueWithMultiEpisodeFile();
      addTearDown(p.dispose);

      final next = await p.getNextEpisode('e24', playedPartId: 'part-e24');
      expect(next!.id, 'e26');
    });

    test('getNextEpisode skips the same-file sibling via file intersection without playedPartId', () async {
      final p = await queueWithMultiEpisodeFile();
      addTearDown(p.dispose);

      final next = await p.getNextEpisode('e24');
      expect(next!.id, 'e26');
    });

    test('getNextEpisode skips multiple siblings of a triple-episode file', () async {
      final p = PlaybackStateProvider();
      addTearDown(p.dispose);
      await p.setPlaybackFromPlayQueue(
        _queue(
          playQueueID: 1,
          selectedItemID: 1001,
          totalCount: 4,
          items: [
            _itemWithFile('e1', 1001, fileA),
            _itemWithFile('e2', 1002, fileA),
            _itemWithFile('e3', 1003, fileA),
            _itemWithFile('e4', 1004, '/tv/S02E26-E27.mkv'),
          ],
        ),
        null,
      );

      final next = await p.getNextEpisode('e1', playedPartId: 'part-e1');
      expect(next!.id, 'e4');
    });

    test('getNextEpisode returns null when only same-file siblings remain', () async {
      final p = PlaybackStateProvider();
      addTearDown(p.dispose);
      await p.setPlaybackFromPlayQueue(
        _queue(
          playQueueID: 1,
          selectedItemID: 1001,
          totalCount: 2,
          items: [_itemWithFile('e24', 1001, fileA), _itemWithFile('e25', 1002, fileA)],
        ),
        null,
      );

      expect(await p.getNextEpisode('e24', playedPartId: 'part-e24'), isNull);
    });

    test('items without file data keep positional behavior even with playedPartId', () async {
      final p = PlaybackStateProvider();
      addTearDown(p.dispose);
      final items = [_item('a', 1001), _item('b', 1002)];
      await p.setPlaybackFromPlayQueue(_queue(playQueueID: 1, selectedItemID: 1001, totalCount: 2, items: items), null);

      final next = await p.getNextEpisode('a', playedPartId: 'part-a');
      expect(next!.id, 'b');
    });

    test('skip past the loaded window extends it and lands on the next distinct file', () async {
      final p = PlaybackStateProvider();
      addTearDown(p.dispose);
      // Window holds only the two same-file entries; e26 lives past it.
      final windowItems = [_itemWithFile('e24', 1001, fileA), _itemWithFile('e25', 1002, fileA)];
      await p.setPlaybackFromPlayQueue(
        _queue(playQueueID: 1, selectedItemID: 1001, totalCount: 3, items: windowItems),
        null,
      );

      var fetchCount = 0;
      p.setPlayQueueWindowFetcher((playQueueId, {center, window = 50}) async {
        fetchCount++;
        return _queue(
          playQueueID: playQueueId,
          selectedItemID: 1001,
          totalCount: 3,
          items: [...windowItems, _itemWithFile('e26', 1003, '/tv/S02E26-E27.mkv')],
        );
      });

      final next = await p.getNextEpisode('e24', playedPartId: 'part-e24');
      expect(next!.id, 'e26');
      expect(fetchCount, 1);
    });

    test('getPreviousEpisode collapses to the first episode of the same-file group', () async {
      final p = await queueWithMultiEpisodeFile(selectedItemID: 1004);
      addTearDown(p.dispose);

      // From e26, previous is the e24-e25 file, entered at e24 (not e25).
      final prev = await p.getPreviousEpisode('e26', playedPartId: 'part-e26');
      expect(prev!.id, 'e24');
    });

    test('getPreviousEpisode skips same-file siblings of the playing item', () async {
      final p = await queueWithMultiEpisodeFile(selectedItemID: 1003);
      addTearDown(p.dispose);

      // Playing the file as e25: previous must not land inside the same file.
      final prev = await p.getPreviousEpisode('e25', playedPartId: 'part-e25');
      expect(prev!.id, 'e23');
    });

    test('sameFileSiblings returns the other episodes of the playing file', () async {
      final p = await queueWithMultiEpisodeFile();
      addTearDown(p.dispose);

      final current = p.loadedItems[1]; // e24
      final siblings = p.sameFileSiblings(current, playedPartId: 'part-e24');
      expect(siblings.map((s) => s.id), ['e25']);

      // Distinct-file episode has no siblings.
      expect(p.sameFileSiblings(p.loadedItems.first, playedPartId: 'part-e23'), isEmpty);
    });

    test('sameFileSiblings is empty without an active queue', () {
      final p = PlaybackStateProvider();
      addTearDown(p.dispose);
      expect(p.sameFileSiblings(_itemWithFile('e24', 1, fileA), playedPartId: 'part-e24'), isEmpty);
    });
  });
}
