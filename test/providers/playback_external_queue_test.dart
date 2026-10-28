import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/play_queue.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/services/playback_context.dart';

void main() {
  final item = MediaItem.plex(id: 'remote', kind: MediaKind.movie, title: 'Video');
  late PlaybackStateProvider provider;
  setUp(() => provider = PlaybackStateProvider());
  tearDown(() => provider.dispose());

  test('queue replacement releases an in-flight source instead of attaching it to the new queue', () async {
    final pending = Completer<ExternalPlaybackSource>();
    var releases = 0;
    provider.setPlaybackFromLocalQueue(
      LocalPlayQueue(items: [item]),
      externalSourceResolvers: {item.globalKey: (_) => pending.future},
    );
    final resolved = provider.resolveExternalPlaybackSource(item);
    final rejected = expectLater(resolved, throwsStateError);
    provider.setPlaybackFromLocalQueue(LocalPlayQueue(items: [item]));
    pending.complete(
      ExternalPlaybackSource(
        mediaGlobalKey: item.globalKey,
        profileId: 'alice',
        uri: Uri.parse('https://example.com/video'),
        onRelease: () async {
          releases++;
        },
      ),
    );
    await rejected;
    expect(releases, 1);
  });

  test('wrong-item leases are released, while null retains the normal server resolver', () async {
    var releases = 0;
    provider.setPlaybackFromLocalQueue(
      LocalPlayQueue(items: [item]),
      externalSourceResolvers: {
        item.globalKey: (_) async => ExternalPlaybackSource(
          mediaGlobalKey: 'wrong',
          profileId: 'alice',
          uri: Uri.parse('https://example.com/video'),
          onRelease: () async {
            releases++;
          },
        ),
      },
    );
    await expectLater(provider.resolveExternalPlaybackSource(item), throwsStateError);
    expect(releases, 1);
    provider.setPlaybackFromLocalQueue(
      LocalPlayQueue(items: [item]),
      externalSourceResolvers: {item.globalKey: (_) async => null},
    );
    expect(await provider.resolveExternalPlaybackSource(item), isNull);
  });

  test('mixed server queues retain refreshed metadata and distinguish identical local IDs', () async {
    final first = MediaItem.plex(id: '42', kind: MediaKind.episode, title: 'First', serverId: 'a');
    final second = MediaItem.plex(id: '42', kind: MediaKind.episode, title: 'Second', serverId: 'b');
    provider.setPlaybackFromLocalQueue(LocalPlayQueue(items: [first, second, item], currentIndex: 0));
    final fresh = second.copyWith(viewOffsetMs: 30000);
    expect(provider.isItemInActiveQueue(fresh), isTrue);
    expect((await provider.getNextEpisode(second.globalKey)).item, same(item));
    provider.setCurrentItem(fresh);
    expect(provider.currentQueueItem!.globalKey, second.globalKey);
    expect((await provider.getPreviousEpisode(fresh.globalKey)).item, same(first));
  });

  test('each repeat resolves a fresh lease and release is idempotent', () async {
    var resolutions = 0, releases = 0;
    provider.setPlaybackFromLocalQueue(
      LocalPlayQueue(items: [item]),
      externalSourceResolvers: {
        item.globalKey: (_) async {
          resolutions++;
          return ExternalPlaybackSource(
            mediaGlobalKey: item.globalKey,
            profileId: 'alice',
            uri: Uri.parse('https://example.com/video'),
            onRelease: () async {
              releases++;
            },
          );
        },
      },
    );
    final first = (await provider.resolveExternalPlaybackSource(item))!;
    await Future.wait([first.release(), first.release()]);
    final repeated = (await provider.resolveExternalPlaybackSource(item))!;
    expect(repeated, isNot(same(first)));
    expect(resolutions, 2);
    expect(releases, 1);
    await repeated.release();
    expect(releases, 2);
  });
}
