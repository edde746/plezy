import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/services/video_filter_manager.dart';

void main() {
  test('zoom scale snaps to whole percentages', () {
    final player = _RecordingPlayer();
    final manager = VideoFilterManager(player: player, availableVersions: const [], selectedMediaIndex: 0);
    addTearDown(manager.dispose);

    expect(manager.setZoomScale(1.234), 1.23);
    expect(manager.zoomScale, 1.23);

    expect(manager.adjustZoom(VideoFilterManager.zoomStep), 1.24);
    expect(manager.zoomScale, 1.24);
  });

  test('zoom scale snaps near 100 percent to exact default', () {
    final player = _RecordingPlayer();
    final manager = VideoFilterManager(player: player, availableVersions: const [], selectedMediaIndex: 0);
    addTearDown(manager.dispose);

    manager.setZoomScale(1.5);

    expect(manager.setZoomScale(1.00008), 1.0);
    expect(manager.zoomScale, 1.0);
    expect(manager.resetZoom(), 1.0);
  });

  test('video zoom property is exact zero at normalized default', () async {
    final player = _RecordingPlayer();
    final manager = VideoFilterManager(player: player, availableVersions: const [], selectedMediaIndex: 0);
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
    final manager = VideoFilterManager(
      player: player,
      availableVersions: const [],
      selectedMediaIndex: 0,
      initialBoxFitMode: 2,
      initialPlayerSize: const Size(1920, 1080),
    );
    addTearDown(manager.dispose);

    await manager.updateVideoFilter();

    final aspectWrites = player.writes.where((write) => write.key == 'video-aspect-override').toList();
    expect(aspectWrites, isNotEmpty);
    expect(double.parse(aspectWrites.last.value), closeTo(16 / 9, 0.0001));
  });
}

class _RecordingPlayer implements Player {
  final writes = <MapEntry<String, String>>[];

  @override
  Future<void> setProperty(String name, String value) async {
    writes.add(MapEntry(name, value));
  }

  @override
  PlayerState get state => const PlayerState();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
