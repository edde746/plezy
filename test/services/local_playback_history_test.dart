import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';

import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/local_playback_history.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/prefs.dart';
import '../test_helpers/media_items.dart';

void main() {
  setUp(() {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    LocalPlaybackHistory.resetForTesting();
  });

  test('recordPlayback writes item and series keys for an episode', () async {
    final episode = testMediaItem(
      id: 'ep-1',
      backend: MediaBackend.plex,
      kind: MediaKind.episode,
      title: 'Episode 1',
      serverId: 'srv-1',
      grandparentId: 'show-1',
    );

    await LocalPlaybackHistory.recordPlayback(episode);

    final history = await LocalPlaybackHistory.snapshot();
    expect(history.keys, containsAll(['srv-1:ep-1', 'srv-1:show-1']));
    expect(history['srv-1:ep-1'], history['srv-1:show-1']);
  });

  test('recordPlayback writes only the item key for a movie', () async {
    final movie = testMediaItem(
      id: 'movie-1',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Movie',
      serverId: 'srv-1',
    );

    await LocalPlaybackHistory.recordPlayback(movie);

    final history = await LocalPlaybackHistory.snapshot();
    expect(history.keys, ['srv-1:movie-1']);
  });

  test('repeat writes for the same item within the rewrite window are skipped', () async {
    final movie = testMediaItem(
      id: 'movie-1',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Movie',
      serverId: 'srv-1',
    );

    await LocalPlaybackHistory.recordPlayback(movie);
    final first = (await LocalPlaybackHistory.snapshot())['srv-1:movie-1'];
    await LocalPlaybackHistory.recordPlayback(movie);
    final second = (await LocalPlaybackHistory.snapshot())['srv-1:movie-1'];

    expect(second, first);
  });

  test('prunes the oldest entries past the cap', () async {
    final settings = await SettingsService.getInstance();
    await settings.write(SettingsService.localLastPlayedAt, {for (var i = 0; i < 400; i++) 'srv-1:old-$i': i + 1});

    final movie = testMediaItem(
      id: 'fresh',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Fresh',
      serverId: 'srv-1',
    );
    await LocalPlaybackHistory.recordPlayback(movie);

    final history = await LocalPlaybackHistory.snapshot();
    expect(history.length, 400);
    expect(history, contains('srv-1:fresh'));
    // The oldest entry (value 1) was evicted to make room.
    expect(history, isNot(contains('srv-1:old-0')));
  });
}
