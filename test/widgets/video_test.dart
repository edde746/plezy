import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/player/player.dart';
import 'package:plezy/mpv/player/player_state.dart';
import 'package:plezy/mpv/player/player_streams.dart';
import 'package:plezy/mpv/player/video_rect_support.dart';
import 'package:plezy/mpv/video.dart';

class _FakePlayer implements Player {
  @override
  final PlayerStreams streams = const PlayerStreams(
    playing: Stream.empty(),
    completed: Stream.empty(),
    buffering: Stream.empty(),
    position: Stream.empty(),
    duration: Stream.empty(),
    seekable: Stream.empty(),
    buffer: Stream.empty(),
    volume: Stream.empty(),
    rate: Stream.empty(),
    tracks: Stream.empty(),
    track: Stream.empty(),
    log: Stream.empty(),
    error: Stream.empty(),
    audioDevice: Stream.empty(),
    audioDevices: Stream.empty(),
    bufferRanges: Stream.empty(),
    playbackRestart: Stream.empty(),
    backendSwitched: Stream.empty(),
  );

  @override
  PlayerState get state => const PlayerState();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRectPlayer extends _FakePlayer implements VideoRectSupport {
  final List<({int left, int top, int right, int bottom})> rects = [];

  @override
  Future<void> setVideoRect({
    required int left,
    required int top,
    required int right,
    required int bottom,
    required double devicePixelRatio,
  }) async {
    rects.add((left: left, top: top, right: right, bottom: bottom));
  }
}

void main() {
  testWidgets('rectUpdateListenable tracks paint-only movement without duplicate native updates', (tester) async {
    final geometryChanges = ChangeNotifier();
    final player = _FakeRectPlayer();
    var offset = 0.0;
    addTearDown(geometryChanges.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: AnimatedBuilder(
              animation: geometryChanges,
              child: SizedBox(
                width: 160,
                height: 90,
                child: Video(player: player, rectUpdateListenable: geometryChanges),
              ),
              builder: (context, child) => Transform.translate(offset: Offset(0, offset), child: child),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(player.rects, hasLength(1));
    final initial = player.rects.single;

    offset = 40;
    geometryChanges.notifyListeners();
    await tester.pump();

    expect(player.rects, hasLength(2));
    final physicalDelta = (40 * tester.view.devicePixelRatio).round();
    expect(player.rects.last.top, initial.top + physicalDelta);
    expect(player.rects.last.bottom, initial.bottom + physicalDelta);

    geometryChanges.notifyListeners();
    await tester.pump();

    expect(player.rects, hasLength(2));
  });
}
