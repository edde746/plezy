import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/play_queue.dart';
import 'package:plezy/models/plex/play_queue_response.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/services/repeating_playlist_launcher.dart';

MediaItem _item(String id) =>
    MediaItem(id: id, backend: MediaBackend.plex, kind: MediaKind.episode, title: 'Episode $id', serverId: 'server-1');

void main() {
  group('video playlist repeat', () {
    test('the launcher queue keeps all 184 items and the selected index', () {
      final items = List<MediaItem>.generate(184, (index) => _item('$index'));

      final queue = buildRepeatingVideoPlaylistQueue(
        playlistContextKey: 'playlist-200546',
        items: items,
        shuffle: false,
        startIndex: 183,
      );

      expect(queue.items, hasLength(184));
      expect(queue.items.first, same(items.first));
      expect(queue.items.last, same(items.last));
      expect(queue.currentIndex, 183);
      expect(queue.shuffled, isFalse);
    });

    test('shuffle keeps every queue item in a fully resident queue', () {
      final items = List<MediaItem>.generate(184, (index) => _item('$index'));

      final queue = buildRepeatingVideoPlaylistQueue(
        playlistContextKey: 'server-1:playlist-200546',
        items: items,
        shuffle: true,
        random: Random(7),
      );

      expect(queue.items, hasLength(184));
      expect(queue.items, unorderedEquals(items));
      expect(queue.currentIndex, 0);
      expect(queue.shuffled, isTrue);
    });

    test('a 184-item local queue wraps from its final item to index zero', () async {
      final items = List<MediaItem>.generate(184, (index) => _item('$index'));
      final provider = PlaybackStateProvider();
      addTearDown(provider.dispose);

      const playlistId = 'playlist-200546';
      provider.setRepeatForContext(playlistId, true);
      provider.setPlaybackFromLocalQueue(
        LocalPlayQueue(
          id: 'plex:playlist:$playlistId:test',
          items: items,
          backendId: MediaBackend.plex.id,
          currentIndex: items.length - 1,
        ),
        contextKey: playlistId,
      );

      expect(provider.isRepeatActive, isTrue);
      final result = await provider.getNextEpisode(items.last.id, loopQueue: provider.isRepeatActive);

      expect(result.status, QueueNavigationStatus.found);
      expect(result.item, same(items.first));
    });

    test('a one-item local queue repeats the same queue entry', () async {
      final item = _item('only');
      final provider = PlaybackStateProvider();
      addTearDown(provider.dispose);

      const playlistId = 'one-item-playlist';
      provider.setRepeatForContext(playlistId, true);
      provider.setPlaybackFromLocalQueue(
        LocalPlayQueue(
          id: 'plex:playlist:$playlistId:test',
          items: [item],
          backendId: MediaBackend.plex.id,
          currentIndex: 0,
        ),
        contextKey: playlistId,
      );

      final result = await provider.getNextEpisode(item.id, loopQueue: provider.isRepeatActive);

      expect(result.status, QueueNavigationStatus.found);
      expect(result.item, same(item));
    });

    test('local Plex queues ignore stale server queue ids', () {
      final first = PlexMediaItem(
        id: 'first',
        kind: MediaKind.episode,
        playQueueItemId: 1,
        title: 'First',
        serverId: 'server-1',
      );
      final second = PlexMediaItem(
        id: 'second',
        kind: MediaKind.episode,
        playQueueItemId: 0,
        title: 'Second',
        serverId: 'server-1',
      );
      final provider = PlaybackStateProvider();
      addTearDown(provider.dispose);

      provider.setPlaybackFromLocalQueue(
        LocalPlayQueue(
          id: 'plex:playlist:stale-id-test',
          items: [first, second],
          backendId: MediaBackend.plex.id,
          currentIndex: 1,
        ),
        contextKey: 'server-1:stale-id-test',
      );

      expect(provider.playQueueItemIdFor(first), 0);
      expect(provider.playQueueItemIdFor(second), 1);
      expect(provider.currentQueueItem, same(second));
      provider.setCurrentItem(first);
      expect(provider.currentPlayQueueItemID, 0);
      expect(provider.currentQueueItem, same(first));
    });

    test('a windowed Plex server queue is never fake-wrapped', () async {
      final first = PlexMediaItem(id: 'first', kind: MediaKind.episode, playQueueItemId: 1001, title: 'First');
      final last = PlexMediaItem(id: 'last', kind: MediaKind.episode, playQueueItemId: 9007, title: 'Last');
      final provider = PlaybackStateProvider();
      addTearDown(provider.dispose);

      const playlistId = 'server-window-playlist';
      provider.setRepeatForContext(playlistId, true);
      await provider.setPlaybackFromPlayQueue(
        PlayQueueResponse(
          playQueueID: 77,
          playQueueSelectedItemID: 9007,
          playQueueShuffled: false,
          playQueueTotalCount: 184,
          playQueueVersion: 1,
          size: 2,
          items: [first, last],
        ),
        playlistId,
      );

      expect(provider.isRepeatActive, isFalse);
      final result = await provider.getNextEpisode(last.id, loopQueue: true);

      expect(result.status, QueueNavigationStatus.failed);
      expect(result.item, isNull);
    });

    test('the same local queue reports a boundary when repeat is off', () async {
      final items = <MediaItem>[_item('first'), _item('last')];
      final provider = PlaybackStateProvider();
      addTearDown(provider.dispose);

      provider.setPlaybackFromLocalQueue(
        LocalPlayQueue(
          id: 'plex:playlist:no-repeat:test',
          items: items,
          backendId: MediaBackend.plex.id,
          currentIndex: 1,
        ),
        contextKey: 'no-repeat',
      );

      final result = await provider.getNextEpisode(items.last.id, loopQueue: false);

      expect(result.status, QueueNavigationStatus.boundary);
      expect(result.item, isNull);
    });

    test('repeat is active only for its fully resident local playlist queue', () {
      final items = <MediaItem>[_item('first'), _item('last')];
      final provider = PlaybackStateProvider();
      addTearDown(provider.dispose);

      const playlistId = 'playlist-local-only';
      provider.setRepeatForContext(playlistId, true);
      expect(provider.isRepeatActive, isFalse);

      provider.setPlaybackFromLocalQueue(
        LocalPlayQueue(
          id: 'plex:playlist:$playlistId:test',
          items: items,
          backendId: MediaBackend.plex.id,
          currentIndex: 0,
        ),
        contextKey: playlistId,
      );
      expect(provider.isRepeatActive, isTrue);

      provider.clearShuffle();
      expect(provider.isRepeatActive, isFalse);
      expect(provider.isRepeatEnabledFor(playlistId), isTrue);
    });
  });
}
