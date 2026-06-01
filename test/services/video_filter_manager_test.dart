import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/services/video_filter_manager.dart';

void main() {
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
