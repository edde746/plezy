import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_hub.dart';

MediaHub _hub({required String id, String? identifier}) {
  return MediaHub(id: id, identifier: identifier, title: 'Hub', type: 'mixed', items: const []);
}

void main() {
  group('MediaHub continue watching semantics', () {
    test('recognizes Plex in-progress hubs as continue watching rows', () {
      final hub = _hub(id: '/hubs/sections/1', identifier: 'movie.inprogress.1');

      expect(hub.isContinueWatchingHub, isTrue);
      expect(hub.usesContinueWatchingAction, isTrue);
    });

    test('recognizes Jellyfin continue hubs as continue watching rows', () {
      final hub = _hub(id: 'library.lib-99.continue');
      final homeHub = _hub(id: 'home.continue');

      expect(hub.isContinueWatchingHub, isTrue);
      expect(hub.usesContinueWatchingAction, isTrue);
      expect(homeHub.isContinueWatchingHub, isTrue);
      expect(homeHub.usesContinueWatchingAction, isTrue);
    });

    test('recognizes synthetic home continue watching hub', () {
      final hub = _hub(id: 'continue_watching', identifier: '_continue_watching_');

      expect(hub.isContinueWatchingHub, isTrue);
      expect(hub.usesContinueWatchingAction, isTrue);
    });

    test('uses continue watching action for next up without removal semantics', () {
      final hub = _hub(id: 'library.lib-99.nextup');
      final homeHub = _hub(id: 'home.nextup');

      expect(hub.isContinueWatchingHub, isFalse);
      expect(hub.usesContinueWatchingAction, isTrue);
      expect(homeHub.isContinueWatchingHub, isFalse);
      expect(homeHub.usesContinueWatchingAction, isTrue);
    });

    test('uses continue watching action for Plex on deck without removal semantics', () {
      final hub = _hub(id: '/hubs/sections/1', identifier: 'tv.ondeck.1');

      expect(hub.isContinueWatchingHub, isFalse);
      expect(hub.usesContinueWatchingAction, isTrue);
    });

    test('does not match unrelated hubs or library ids containing semantic words', () {
      final recent = _hub(id: 'library.lib-99.recent');
      final libraryNamedNextUp = _hub(id: 'library.nextup.recent');

      expect(recent.isContinueWatchingHub, isFalse);
      expect(recent.usesContinueWatchingAction, isFalse);
      expect(libraryNamedNextUp.isContinueWatchingHub, isFalse);
      expect(libraryNamedNextUp.usesContinueWatchingAction, isFalse);
    });
  });
}
