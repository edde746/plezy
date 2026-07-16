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

    expect(manager.adjustZoom(VideoFilterManager.zoomStep), 1.24);
    expect(manager.zoomScale, 1.24);
  });

  test('zoom scale snaps near 100 percent to exact default', () {
    final player = _RecordingPlayer();
    final manager = VideoFilterManager(player: player);
    addTearDown(manager.dispose);

    manager.setZoomScale(1.5);

    expect(manager.setZoomScale(1.00008), 1.0);
    expect(manager.zoomScale, 1.0);
    expect(manager.resetZoom(), 1.0);
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
