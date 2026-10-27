import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/models.dart';
import 'package:plezy/mpv/player/platform/player_tizen.dart';
import 'package:video_player_videohole/video_player.dart' as samsung;
import 'package:video_player_videohole/video_player_platform_interface.dart' as native;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeSamsung backend;
  late PlayerTizen player;

  setUp(() {
    backend = FakeSamsung();
    native.VideoPlayerPlatform.instance = backend;
    player = PlayerTizen();
  });
  tearDown(() => player.dispose());

  test('authenticated remote URLs stay behind the local transport', () async {
    await player.open(Media('https://server.test/movie.mp4?token=secret', headers: {'Authorization': 'Bearer secret'}));
    final source = backend.sources.single;
    expect(Uri.parse(source.uri!).host, '127.0.0.1');
    expect(source.uri, isNot(contains('secret')));
    expect(source.httpHeaders, isEmpty);
    expect(player.state.playing, isTrue);
    expect(player.state.tracks.audio.single.id, '4');
    expect(player.state.track.subtitle?.id, 'no');
  });

  test('timeline offsets and seeking at non-unit speed preserve item time', () async {
    await player.open(
      Media('/movie.mp4', start: const Duration(seconds: 45)),
      timelineOffset: const Duration(seconds: 30),
      timelineDuration: const Duration(minutes: 5),
    );
    expect(backend.seeks.last, const Duration(seconds: 15));
    expect(player.currentPosition, const Duration(seconds: 45));
    expect(player.state.duration, const Duration(minutes: 5));
    expect(
      player.state.hasRenderedFrame,
      isFalse,
      reason: 'seek/play are optimistic until the playback clock advances',
    );
    backend.position = const Duration(seconds: 16);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(player.state.hasRenderedFrame, isTrue);
    await player.setRate(1.5);
    backend.rates.clear();
    await player.seek(const Duration(seconds: 70));
    expect(backend.seeks.last, const Duration(seconds: 40));
    expect(backend.rates, [1.0, 1.5]);
    expect(player.currentPosition, const Duration(seconds: 70));
  });

  test('failed native creation is sanitized, releases disposal and allows retry', () async {
    backend.failCreate = true;
    await expectLater(
      player.open(Media('/movie.mp4')),
      throwsA(isA<PlatformException>().having((e) => e.message, 'message', isNot(contains('secret')))),
    );
    backend.failCreate = false;
    await player.open(Media('/retry.mp4'));
    expect(player.state.playing, isTrue);
    await player.dispose().timeout(const Duration(seconds: 2));
    await player.dispose();
    expect(backend.disposed, [1]);
  });

  test('pre-open volume and rate are restored on replacement sources', () async {
    await player.setVolume(35);
    await player.setRate(1.25);
    await player.open(Media('/first.mp4'));
    await player.open(Media('/second.mp4'));
    expect(backend.volumes.last, 0.35);
    expect(backend.rates.last, 1.25);
  });

  test('stop during preparation cannot start a stale source', () async {
    backend.prepareGate = Completer<void>();
    final opening = player.open(Media('/movie.mp4'));
    await backend.preparing.future;
    final stopping = player.stop();
    backend.prepareGate!.complete();
    await Future.wait([opening, stopping]);
    expect(backend.played, isEmpty);
    expect(backend.disposed, [1]);
    expect(player.state.seekable, isFalse);
  });

  test('rejected native track selection leaves the selected track unchanged', () async {
    await player.open(Media('/movie.mp4'));
    backend.acceptTrack = false;
    await expectLater(player.selectSubtitleTrack(const SubtitleTrack(id: '7')), throwsA(isA<PlatformException>()));
    expect(player.state.track.subtitle?.id, 'no');
    expect(player.caption.value, isEmpty);
  });

  test('native captions can be hidden without enabling a different track', () async {
    await player.open(Media('/movie.mp4'));
    await player.selectSubtitleTrack(const SubtitleTrack(id: '7'));
    backend.events[1]!.add(
      native.VideoEvent(
        eventType: native.VideoEventType.subtitleUpdate,
        text: 'Hello',
        duration: native.DurationRange(Duration.zero, const Duration(seconds: 2)),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(player.caption.value, 'Hello');
    await player.selectSubtitleTrack(SubtitleTrack.off);
    expect(player.caption.value, isEmpty);
    await player.setProperty('sub-visibility', 'yes');
    expect(player.caption.value, isEmpty);
  });

  test('live native completion never marks the programme watched', () async {
    await player.open(Media('/live.ts'), isLive: true);
    backend.events[1]!.add(native.VideoEvent(eventType: native.VideoEventType.completed));
    await Future<void>.delayed(Duration.zero);
    expect(player.state.completed, isFalse);
    expect(player.state.seekable, isFalse);
  });

  test('audio completion advances once and reports the original next URI', () async {
    await player.dispose();
    player = PlayerTizen(audioOnly: true);
    final transition = player.streams.trackTransition.first;
    await player.open(Media('/first.mp3'));
    await player.setNext(Media('/second.mp3'));
    backend.events[1]!.add(native.VideoEvent(eventType: native.VideoEventType.completed));
    expect(await transition.timeout(const Duration(seconds: 2)), '/second.mp3');
    expect(backend.sources, hasLength(2));
    expect(backend.disposed, [1]);
  });

  testWidgets('unmounted video surface stops its frame callback', (tester) async {
    final controller = samsung.VideoPlayerController.file(File('/movie.mp4'));
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(data: const MediaQueryData(), child: samsung.VideoPlayer(controller)),
      ),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
    await controller.dispose();
  });
}

class FakeSamsung extends native.VideoPlayerPlatform {
  final sources = <native.DataSource>[];
  final events = <int, StreamController<native.VideoEvent>>{};
  final disposed = <int>[];
  final played = <int>[];
  final seeks = <Duration>[];
  final rates = <double>[];
  final volumes = <double>[];
  final preparing = Completer<void>();
  Completer<void>? prepareGate;
  bool failCreate = false;
  bool acceptTrack = true;
  Duration position = Duration.zero;

  @override
  Future<void> init() async {}
  @override
  Future<int?> create(native.DataSource source) async {
    if (failCreate) throw PlatformException(code: 'create', message: 'https://server.test/?token=secret');
    sources.add(source);
    final id = sources.length;
    events[id] = StreamController<native.VideoEvent>();
    return id;
  }

  @override
  Future<void> prepare(int playerId) async {
    if (!preparing.isCompleted) preparing.complete();
    await prepareGate?.future;
    events[playerId]!.add(
      native.VideoEvent(
        eventType: native.VideoEventType.initialized,
        duration: native.DurationRange(Duration.zero, const Duration(minutes: 2)),
        size: const Size(1920, 1080),
      ),
    );
  }

  @override
  Stream<native.VideoEvent> videoEventsFor(int playerId) => events[playerId]!.stream;
  @override
  Future<void> dispose(int playerId) async {
    disposed.add(playerId);
    await events[playerId]?.close();
  }

  @override
  Future<void> play(int playerId) async => played.add(playerId);
  @override
  Future<void> pause(int playerId) async {}
  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async => volumes.add(volume);
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async => rates.add(speed);
  @override
  Future<void> seekTo(int playerId, Duration target) async {
    position = target;
    seeks.add(target);
  }

  @override
  Future<Duration> getPosition(int playerId) async => position;
  @override
  Future<native.DurationRange> getDuration(int playerId) async =>
      native.DurationRange(Duration.zero, const Duration(minutes: 2));
  @override
  Future<List<samsung.AudioTrack>> getAudioTracks(int playerId) async => [
    samsung.AudioTrack(trackId: 4, language: 'en', channel: 2, bitrate: 128000),
  ];
  @override
  Future<List<samsung.TextTrack>> getTextTracks(int playerId) async => [samsung.TextTrack(trackId: 7, language: 'en')];
  @override
  Future<bool> setTrackSelection(int playerId, samsung.Track track) async => acceptTrack;
}
