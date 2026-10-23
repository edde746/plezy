import 'dart:ui' as ui;

import 'package:clock/clock.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/services/playback_coordinator.dart';
import 'package:plezy/utils/memory_pressure_breadcrumbs.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// The production binding's memory-pressure hook over the standard test
/// binding, so a `memoryPressure` system message takes the engine's path.
class _MemoryPressureTestBinding extends AutomatedTestWidgetsFlutterBinding with MemoryPressureBreadcrumbs {
  /// The engine message runs in the zone that registered the channel handler,
  /// out of reach of `withClock`; timing cases enter the handler directly.
  void warnInCurrentZone() => handleMemoryPressure();
}

/// Evicts the way `_MainAppState.didHaveMemoryPressure` does, and records what
/// an observer gets to see of the cache.
class _EvictingObserver with WidgetsBindingObserver {
  int? keepAliveBytesSeen;

  @override
  void didHaveMemoryPressure() {
    final cache = PaintingBinding.instance.imageCache;
    keepAliveBytesSeen = cache.currentSizeBytes;
    cache
      ..clear()
      ..clearLiveImages();
  }
}

class _LoadedImageCompleter extends ImageStreamCompleter {
  _LoadedImageCompleter(ui.Image image) {
    setImage(ImageInfo(image: image));
  }
}

void main() {
  final binding = _MemoryPressureTestBinding();
  late List<Breadcrumb> breadcrumbs;

  setUp(() async {
    binding.debugResetMemoryPressureBreadcrumbs();
    breadcrumbs = [];
    await Sentry.init((options) {
      options
        ..dsn = 'https://public@example.com/1'
        ..beforeBreadcrumb = (breadcrumb, hint) {
          if (breadcrumb?.category == 'memory.pressure') breadcrumbs.add(breadcrumb!);
          return breadcrumb;
        };
    });
    addTearDown(Sentry.close);
  });

  tearDown(() {
    binding.imageCache
      ..clear()
      ..clearLiveImages();
  });

  void registerVideoSession(PlayerState? Function() playerState) {
    Future<void> owner() async {}
    PlaybackCoordinator.instance.registerVideoSession(shutdown: owner, playerState: playerState);
    addTearDown(() => PlaybackCoordinator.instance.unregisterVideoSession(owner));
  }

  void warnAt(DateTime at) => withClock(Clock.fixed(at), binding.warnInCurrentZone);

  test('records the image cache from before the framework cleared it and after the app evicted', () async {
    final cache = binding.imageCache;
    final keepAliveImage = await createTestImage(width: 1024, height: 1024); // 4 MB
    final shownImage = await createTestImage(width: 1024, height: 512); // 2 MB
    cache.putIfAbsent('keep-alive', () => _LoadedImageCompleter(keepAliveImage));
    final shownListener = ImageStreamListener((info, _) => info.dispose());
    final shown = cache.putIfAbsent('shown', () => _LoadedImageCompleter(shownImage)..addListener(shownListener))!;
    addTearDown(() => shown.removeListener(shownListener));
    expect((cache.currentSize, cache.liveImageCount), (2, 1));

    final observer = _EvictingObserver();
    binding.addObserver(observer);
    addTearDown(() => binding.removeObserver(observer));
    registerVideoSession(
      () => const PlayerState(playing: true, position: Duration(minutes: 1), buffer: Duration(seconds: 95)),
    );

    await binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.system.name,
      SystemChannels.system.codec.encodeMessage(<String, Object?>{'type': 'memoryPressure'}),
      (_) {},
    );

    expect(observer.keepAliveBytesSeen, 0, reason: 'the framework empties the cache before observers run');
    final breadcrumb = breadcrumbs.single;
    expect(breadcrumb.message, 'Memory pressure');
    expect(breadcrumb.level, SentryLevel.warning);
    final data = Map<String, dynamic>.of(breadcrumb.data!);
    final rssMb = data.remove('rssMb') as int;
    final maxRssMb = data.remove('maxRssMb') as int;
    expect(rssMb, greaterThan(0));
    expect(maxRssMb, greaterThanOrEqualTo(rssMb));
    expect(data, {
      'imageCacheMb': 6,
      'imageCacheImages': 2,
      'liveImages': 1,
      'videoSession': true,
      'playbackActive': true,
      'bufferAheadMs': 35000,
      'imageCacheMbAfter': 0,
      'imageCacheImagesAfter': 0,
      'liveImagesAfter': 0,
    });
  });

  test('a burst records once and the next breadcrumb counts the warnings it absorbed', () {
    // The shape of the #445 reports: warnings bunched within seconds, then a
    // straggler just inside the interval.
    final start = DateTime.utc(2026, 10, 20, 16, 36, 39);
    warnAt(start);
    warnAt(start.add(const Duration(milliseconds: 200)));
    warnAt(start.add(const Duration(seconds: 2)));
    warnAt(start.add(const Duration(seconds: 29)));
    expect(breadcrumbs, hasLength(1));
    expect(breadcrumbs.single.data, isNot(contains('suppressed')));

    warnAt(start.add(MemoryPressureBreadcrumbs.breadcrumbInterval));
    expect(breadcrumbs, hasLength(2));
    expect(breadcrumbs.last.data, containsPair('suppressed', 3));

    warnAt(start.add(MemoryPressureBreadcrumbs.breadcrumbInterval * 2));
    expect(breadcrumbs, hasLength(3));
    expect(breadcrumbs.last.data, isNot(contains('suppressed')));
  });

  test('reports player fields only for a built player and never a negative buffer', () {
    final start = DateTime.utc(2026, 10, 20);
    warnAt(start);
    expect(breadcrumbs.last.data, containsPair('videoSession', false));
    expect(breadcrumbs.last.data, isNot(contains('playbackActive')));

    PlayerState? playerState;
    registerVideoSession(() => playerState);
    warnAt(start.add(MemoryPressureBreadcrumbs.breadcrumbInterval));
    expect(breadcrumbs.last.data, containsPair('videoSession', true));
    expect(breadcrumbs.last.data, isNot(contains('bufferAheadMs')));

    // A forward seek past the cached range leaves the playhead ahead of the
    // cache end until the demuxer refills.
    playerState = const PlayerState(position: Duration(minutes: 5), buffer: Duration(minutes: 2));
    warnAt(start.add(MemoryPressureBreadcrumbs.breadcrumbInterval * 2));
    expect(breadcrumbs.last.data, containsPair('playbackActive', false));
    expect(breadcrumbs.last.data, containsPair('bufferAheadMs', 0));
  });
}
