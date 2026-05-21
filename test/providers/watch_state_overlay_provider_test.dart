import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/media/media_backend.dart';
import 'package:vibe_stream/media/media_item.dart';
import 'package:vibe_stream/media/media_kind.dart';
import 'package:vibe_stream/providers/watch_state_overlay_provider.dart';
import 'package:vibe_stream/utils/watch_state_notifier.dart';

MediaItem _item({String id = '1', int? viewOffsetMs, int? viewCount = 0}) {
  return MediaItem(
    id: id,
    backend: MediaBackend.plex,
    kind: MediaKind.movie,
    title: 'Movie',
    serverId: 'server',
    durationMs: 100000,
    viewOffsetMs: viewOffsetMs,
    viewCount: viewCount,
  );
}

Future<void> _drainEvents() => Future<void>.delayed(Duration.zero);

void main() {
  group('WatchStateOverlayProvider', () {
    test('applies watched patches immediately', () async {
      final provider = WatchStateOverlayProvider();
      addTearDown(provider.dispose);
      final item = _item(viewOffsetMs: 40000);

      WatchStateNotifier().notifyWatched(item: item, isNowWatched: true);
      await _drainEvents();

      final patched = provider.apply(item);
      expect(patched.isWatched, isTrue);
      expect(patched.viewOffsetMs, 0);
    });

    test('applies progress patches without changing watched state', () async {
      final provider = WatchStateOverlayProvider();
      addTearDown(provider.dispose);
      final item = _item(viewCount: 1);

      WatchStateNotifier().notifyProgress(item: item, viewOffset: 30000, duration: 100000);
      await _drainEvents();

      final patched = provider.apply(item);
      expect(patched.isWatched, isTrue);
      expect(patched.viewOffsetMs, 30000);
    });

    test('clears patches when active profile changes', () async {
      final provider = WatchStateOverlayProvider();
      addTearDown(provider.dispose);
      final item = _item();

      provider.setActiveProfileId('a');
      WatchStateNotifier().notifyWatched(item: item, isNowWatched: true);
      await _drainEvents();
      expect(provider.apply(item).isWatched, isTrue);

      provider.setActiveProfileId('b');
      expect(provider.apply(item).isWatched, isFalse);
    });
  });
}
