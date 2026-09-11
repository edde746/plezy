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

  test('late shutdown and stop wait for retired reporting and native cleanup', () async {
    final coordinator = PlaybackCoordinator.instance;
    final report = Completer<void>();
    final nativeDisposal = Completer<void>();
    Future<void> owner() async {}
    final retirement = () async {
      await Future.wait<void>([report.future, nativeDisposal.future]);
    }();
    coordinator.registerVideoSession(shutdown: owner);
    coordinator.unregisterVideoSession(owner, retirement: retirement);
    addTearDown(() async {
      if (!report.isCompleted) report.complete();
      if (!nativeDisposal.isCompleted) nativeDisposal.complete();
      coordinator.unregisterVideoSession(owner);
      await coordinator.shutdownVideo();
    });

    expect(coordinator.hasVideoSession, isTrue);
    var shutdownDone = false;
    var stopDone = false;
    final shutdown = coordinator.shutdownVideo().whenComplete(() => shutdownDone = true);
    final stop = coordinator.stopVideoAndExit().whenComplete(() => stopDone = true);
    await Future<void>.delayed(Duration.zero);
    expect(shutdownDone, isFalse);
    expect(stopDone, isFalse);

    report.complete();
    await Future<void>.delayed(Duration.zero);
    expect(shutdownDone, isFalse);
    expect(stopDone, isFalse);
    expect(coordinator.hasVideoSession, isTrue);

    nativeDisposal.complete();
    await shutdown;
    expect(await stop, isTrue);
    expect(coordinator.hasVideoSession, isFalse);
    await coordinator.shutdownVideo();
    expect(await coordinator.stopVideoAndExit(), isTrue);
  });

  test('predecessor retirement survives replacement and stale unregister retries', () async {
    final coordinator = PlaybackCoordinator.instance;
    final retirement = Completer<void>();
    final activeStopped = Completer<void>();
    var activeStops = 0;
    var activeExits = 0;
    Future<void> oldOwner() async {}
    Future<void> activeOwner() {
      activeStops++;
      return activeStopped.future;
    }

    Future<bool> activeExit() async {
      activeExits++;
      return false;
    }

    coordinator.registerVideoSession(shutdown: oldOwner);
    coordinator.unregisterVideoSession(oldOwner, retirement: retirement.future);
    coordinator.registerVideoSession(shutdown: activeOwner, stopAndExit: activeExit);
    addTearDown(() async {
      if (!retirement.isCompleted) retirement.complete();
      if (!activeStopped.isCompleted) activeStopped.complete();
      coordinator.unregisterVideoSession(oldOwner);
      coordinator.unregisterVideoSession(activeOwner);
      await coordinator.shutdownVideo();
    });

    coordinator.unregisterVideoSession(oldOwner, retirement: retirement.future);
    var shutdownDone = false;
    var stopDone = false;
    final shutdown = coordinator.shutdownVideo().whenComplete(() => shutdownDone = true);
    final stop = coordinator.stopVideoAndExit().whenComplete(() => stopDone = true);
    activeStopped.complete();
    await Future<void>.delayed(Duration.zero);
    expect(activeStops, 1);
    expect(activeExits, 1);
    expect(shutdownDone, isFalse);
    expect(stopDone, isFalse);

    retirement.complete();
    await shutdown;
    expect(await stop, isFalse);
    expect(coordinator.hasVideoSession, isTrue);
    coordinator.unregisterVideoSession(oldOwner);
    expect(await coordinator.stopVideoAndExit(), isFalse);
    expect(activeExits, 2);
    coordinator.unregisterVideoSession(activeOwner);
    expect(coordinator.hasVideoSession, isFalse);
  });

  test('a replaced owner can register retirement without releasing its successor', () async {
    final coordinator = PlaybackCoordinator.instance;
    final retirement = Completer<void>();
    var activeStops = 0;
    Future<void> oldOwner() async {}
    Future<void> activeOwner() async => activeStops++;
    coordinator.registerVideoSession(shutdown: oldOwner);
    coordinator.registerVideoSession(shutdown: activeOwner);
    coordinator.unregisterVideoSession(oldOwner, retirement: retirement.future);
    addTearDown(() async {
      if (!retirement.isCompleted) retirement.complete();
      coordinator.unregisterVideoSession(oldOwner);
      coordinator.unregisterVideoSession(activeOwner);
      await coordinator.shutdownVideo();
    });

    var done = false;
    final shutdown = coordinator.shutdownVideo().whenComplete(() => done = true);
    await Future<void>.delayed(Duration.zero);
    expect(activeStops, 1);
    expect(done, isFalse);

    retirement.complete();
    await shutdown;
    expect(coordinator.hasVideoSession, isTrue);
    await coordinator.shutdownVideo();
    expect(activeStops, 2);
  });

  test('failed retirement reaches waiting callers and releases coordinator state', () async {
    final coordinator = PlaybackCoordinator.instance;
    final retirement = Completer<void>();
    final failure = StateError('native retirement failed');
    Future<void> owner() async {}
    coordinator.registerVideoSession(shutdown: owner);
    coordinator.unregisterVideoSession(owner, retirement: retirement.future);
    addTearDown(() async {
      if (!retirement.isCompleted) retirement.complete();
      coordinator.unregisterVideoSession(owner);
      await coordinator.shutdownVideo();
    });

    final shutdown = expectLater(coordinator.shutdownVideo(), throwsA(same(failure)));
    final stop = expectLater(coordinator.stopVideoAndExit(), throwsA(same(failure)));
    retirement.completeError(failure);
    await Future.wait<void>([shutdown, stop]);
    expect(coordinator.hasVideoSession, isFalse);
    await coordinator.shutdownVideo();
    expect(await coordinator.stopVideoAndExit(), isTrue);
  });

  test('failed retirement is observed even without a shutdown waiter', () async {
    final coordinator = PlaybackCoordinator.instance;
    final retirement = Completer<void>();
    Future<void> owner() async {}
    coordinator.registerVideoSession(shutdown: owner);
    coordinator.unregisterVideoSession(owner, retirement: retirement.future);
    addTearDown(() async {
      if (!retirement.isCompleted) retirement.complete();
      coordinator.unregisterVideoSession(owner);
      await coordinator.shutdownVideo();
    });

    retirement.completeError(StateError('retirement failed after navigation'));
    await Future<void>.delayed(Duration.zero);
    expect(coordinator.hasVideoSession, isFalse);
    expect(await coordinator.stopVideoAndExit(), isTrue);
  });
}
