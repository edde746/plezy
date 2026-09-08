import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/playback_coordinator.dart';

void main() {
  test('stale video release preserves the active owner and waits for its stop', () async {
    final coordinator = PlaybackCoordinator.instance;
    final stopped = Completer<void>();
    var oldStops = 0;
    var musicStops = 0;
    Future<void> oldOwner() async => oldStops++;
    Future<void> activeOwner() => stopped.future;
    Future<void> musicOwner() async => musicStops++;
    coordinator.registerMusicSession(stopAndDispose: musicOwner);
    coordinator.registerVideoSession(shutdown: oldOwner);
    coordinator.registerVideoSession(shutdown: activeOwner);
    addTearDown(() {
      coordinator.unregisterVideoSession(oldOwner);
      coordinator.unregisterVideoSession(activeOwner);
      coordinator.unregisterMusicSession(musicOwner);
    });

    coordinator.unregisterVideoSession(oldOwner);
    var done = false;
    final shutdown = coordinator.shutdownVideo().whenComplete(() => done = true);
    await Future<void>.delayed(Duration.zero);
    expect(done, isFalse);
    expect(oldStops, 0);
    expect(musicStops, 0);
    stopped.complete();
    await shutdown;
    expect(done, isTrue);

    coordinator.unregisterVideoSession(activeOwner);
    await coordinator.shutdownVideo();
    expect(oldStops, 0);
    expect(musicStops, 0);
  });
}
