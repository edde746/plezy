import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/services/ambient_lighting_service.dart';
import 'package:plezy/services/video_filter_manager.dart';

void main() {
  test('zoom scale snaps to whole percentages', () {
    final player = _RecordingPlayer();
    final manager = VideoFilterManager(player: player);
    addTearDown(manager.dispose);

    expect(manager.setZoomScale(1.234), 1.23);
    expect(manager.zoomScale, 1.23);

    expect(manager.setZoomScale(manager.zoomScale + VideoFilterManager.zoomStep), 1.24);
    expect(manager.zoomScale, 1.24);
  });

  test('zoom scale snaps near 100 percent to exact default', () {
    final player = _RecordingPlayer();
    final manager = VideoFilterManager(player: player);
    addTearDown(manager.dispose);

    manager.setZoomScale(1.5);

    expect(manager.setZoomScale(1.00008), 1.0);
    expect(manager.zoomScale, 1.0);
    expect(manager.setZoomScale(1.0), 1.0);
  });

  test('video zoom property is exact zero at normalized default', () async {
    final player = _RecordingPlayer();
    final manager = VideoFilterManager(player: player);
    addTearDown(manager.dispose);

    expect(VideoFilterManager.videoZoomPropertyForScale(1.00008), 0.0);

    manager.setZoomScale(1.00008);
    await Future<void>.delayed(Duration.zero);
    player.writes.clear();

    await manager.updateVideoFilter();

    final zoomWrites = player.writes.where((write) => write.key == 'video-zoom').toList();
    expect(zoomWrites, isNotEmpty);
    expect(zoomWrites.last.value, '0.0');
  });

  test('stretch mode applies the initial player size before a resize event', () async {
    final player = _RecordingPlayer();
    final manager = VideoFilterManager(player: player, initialBoxFitMode: 2, initialPlayerSize: const Size(1920, 1080));
    addTearDown(manager.dispose);

    await manager.updateVideoFilter();

    final aspectWrites = player.writes.where((write) => write.key == 'video-aspect-override').toList();
    expect(aspectWrites, isNotEmpty);
    expect(double.parse(aspectWrites.last.value), closeTo(16 / 9, 0.0001));
  });

  test('cover-mode zoom change writes only video-zoom', () async {
    final player = _RecordingPlayer();
    final manager = VideoFilterManager(player: player, initialBoxFitMode: 1);
    addTearDown(manager.dispose);

    await manager.updateVideoFilter();
    player.clearRecords();

    manager.setZoomScale(1.5);
    await Future<void>.delayed(Duration.zero);

    expect(player.boxFitCalls, isEmpty);
    expect(player.zoomCalls, [1.5]);
    expect(player.writes, hasLength(1));
    expect(player.writes.single.key, 'video-zoom');
    expect(player.writes.single.value, VideoFilterManager.videoZoomPropertyForScale(1.5).toString());
  });

  test('native zoom keeps mpv video-zoom at zero and forwards the scale', () async {
    final player = _RecordingPlayer();
    final manager = VideoFilterManager(player: player, nativeVideoZoom: true);
    addTearDown(manager.dispose);

    await manager.updateVideoFilter();
    player.clearRecords();

    manager.setZoomScale(1.5);
    await Future<void>.delayed(Duration.zero);

    // The native layer gets the real scale; mpv must never see a nonzero
    // video-zoom — on vo_avfoundation it would trigger the Core Image
    // re-render that destroys HDR/Dolby Vision passthrough.
    expect(player.zoomCalls, [1.5]);
    expect(player.writes.where((write) => write.key == 'video-zoom'), isEmpty);

    // Margin forcing still follows the zoom state.
    final marginWrites = player.writes.where((write) => write.key == 'sub-ass-force-margins').toList();
    expect(marginWrites, hasLength(1));
    expect(marginWrites.single.value, 'yes');
  });

  test('repeated run with unchanged state writes nothing', () async {
    final player = _RecordingPlayer();
    final manager = VideoFilterManager(player: player);
    addTearDown(manager.dispose);

    await manager.updateVideoFilter();
    player.clearRecords();

    await manager.updateVideoFilter();

    expect(player.writes, isEmpty);
    expect(player.boxFitCalls, isEmpty);
    expect(player.zoomCalls, isEmpty);
  });

  test('concurrent calls coalesce into one trailing re-run', () async {
    final player = _SlowRecordingPlayer();
    final manager = VideoFilterManager(player: player);
    addTearDown(manager.dispose);

    final first = manager.updateVideoFilter();
    manager.setZoomScale(0.8);
    await first;

    final zoomWrites = player.writes.where((write) => write.key == 'video-zoom').toList();
    expect(zoomWrites, hasLength(2));
    expect(zoomWrites.last.value, VideoFilterManager.videoZoomPropertyForScale(0.8).toString());
    expect(player.writes.where((write) => write.key == 'panscan'), hasLength(1));
    expect(player.writes.where((write) => write.key == 'sub-ass-force-margins'), hasLength(1));
    expect(player.zoomCalls, [1.0, 0.8]);
  });

  test('ambient-active run leaves aspect-override unknown', () async {
    final player = _RecordingPlayer();
    final ambient = _FakeAmbientLightingService(player);
    final manager = VideoFilterManager(player: player)..ambientLightingService = ambient;
    addTearDown(manager.dispose);

    await manager.updateVideoFilter();
    player.clearRecords();

    ambient.fakeEnabled = true;
    await manager.updateVideoFilter();
    expect(player.writes.where((write) => write.key == 'video-aspect-override'), isEmpty);

    ambient.fakeEnabled = false;
    await manager.updateVideoFilter();
    final aspectWrites = player.writes.where((write) => write.key == 'video-aspect-override').toList();
    expect(aspectWrites, hasLength(1));
    expect(aspectWrites.single.value, 'no');
  });

  test('fill mode rewrites aspect on player size change', () async {
    final player = _RecordingPlayer();
    final manager = VideoFilterManager(player: player, initialBoxFitMode: 2, initialPlayerSize: const Size(1920, 1080));
    addTearDown(manager.dispose);

    await manager.updateVideoFilter();
    player.clearRecords();

    manager.updatePlayerSize(const Size(1000, 1000));
    // Cover the 50ms leading+trailing debounce.
    await Future<void>.delayed(const Duration(milliseconds: 120));

    final aspectWrites = player.writes.where((write) => write.key == 'video-aspect-override').toList();
    expect(aspectWrites, hasLength(1));
    expect(double.parse(aspectWrites.single.value), closeTo(1.0, 0.0001));
  });

  // Pinching back is the touch path to an unzoomed picture (#1505). Without a
  // detent, normalizeZoomScale's whole-percent rounding means an unaided pinch
  // leaves the frame at 99% or 101% and the viewer cannot tell why it still
  // looks cropped.
  group('snapPinchZoomScale', () {
    test('snaps to exactly 1.0 inside the detent', () {
      for (final scale in [0.97, 0.99, 1.0, 1.01, 1.03]) {
        expect(VideoFilterManager.snapPinchZoomScale(scale), 1.0, reason: '$scale is within the detent');
      }
    });

    test('leaves scales outside the detent alone', () {
      for (final scale in [0.5, 0.9, 0.96, 1.04, 1.1, 2.0]) {
        expect(VideoFilterManager.snapPinchZoomScale(scale), scale, reason: '$scale is outside the detent');
      }
    });

    test('does not swallow the neighbouring zoom presets', () {
      // The sheet offers 0.9 and 1.1 either side of 100%; a detent that ate
      // them would make those presets unreachable by pinch.
      expect(VideoFilterManager.snapPinchZoomScale(0.9), 0.9);
      expect(VideoFilterManager.snapPinchZoomScale(1.1), 1.1);
    });

    test('keeps the 1% keyboard step escapable', () {
      // zoomStep is 1%, inside the detent — proof the detent is confined to the
      // pinch path and never reaches normalizeZoomScale, or zoom-in from 100%
      // could never leave 100%.
      final stepped = VideoFilterManager.normalizeZoomScale(1.0 + VideoFilterManager.zoomStep);
      expect(stepped, closeTo(1.01, 0.0001));
    });
  });
}

class _RecordingPlayer implements Player {
  final writes = <MapEntry<String, String>>[];
  final boxFitCalls = <int>[];
  final zoomCalls = <double>[];

  void clearRecords() {
    writes.clear();
    boxFitCalls.clear();
    zoomCalls.clear();
  }

  @override
  Future<void> setProperty(String name, String value) async {
    writes.add(MapEntry(name, value));
  }

  @override
  Future<void> setBoxFitMode(int mode) async {
    boxFitCalls.add(mode);
  }

  @override
  Future<void> setVideoZoom(double scale) async {
    zoomCalls.add(scale);
  }

  @override
  PlayerState get state => const PlayerState();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Delays each property write so single-flight coalescing can be observed.
class _SlowRecordingPlayer extends _RecordingPlayer {
  @override
  Future<void> setProperty(String name, String value) async {
    await super.setProperty(name, value);
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
}

class _FakeAmbientLightingService extends AmbientLightingService {
  _FakeAmbientLightingService(super.player);

  bool fakeEnabled = false;

  @override
  bool get isEnabled => fakeEnabled;
}
