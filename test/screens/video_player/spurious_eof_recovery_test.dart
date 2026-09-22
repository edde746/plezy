import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/screens/video_player/media_reload_outcome.dart';
import 'package:plezy/screens/video_player/playback_transition_gate.dart';
import 'package:plezy/screens/video_player/spurious_eof_recovery.dart';
import 'package:plezy/screens/video_player/wakelock_controller.dart';

import '../../test_helpers/media_items.dart';
import '../../test_helpers/watch_together_fakes.dart';

/// A player that answers mpv's `file-size` and `file-format` the way the
/// native core does: strings, or null when the transport has no size for the
/// stream. [onRead] runs before each answer so a test can change state while
/// the interceptor is suspended on the channel.
class _SourcePlayer extends FakeSyncPlayer {
  _SourcePlayer({required super.position, required super.duration, this.fileSize, this.fileFormat = 'mkv'});

  int? fileSize;
  String? fileFormat;
  void Function()? onRead;

  @override
  Future<String?> getProperty(String name) async {
    onRead?.call();
    return switch (name) {
      'file-size' => fileSize?.toString(),
      'file-format' => fileFormat,
      _ => null,
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Severance S02E01 on the test server: the selected video and audio tracks
  // end at 2933.68 s of a 3019.58 s container whose dub tracks run to the end.
  const durationMs = 3019584;
  const positionMs = 2933680;
  const fileBytes = 12572719464;

  _SourcePlayer shortEofPlayer({int? fileSize = fileBytes, String? fileFormat = 'mkv'}) => _SourcePlayer(
    position: const Duration(milliseconds: positionMs),
    duration: const Duration(milliseconds: durationMs),
    fileSize: fileSize,
    fileFormat: fileFormat,
  );

  ({SpuriousEofRecovery recovery, List<Duration> reloads, void Function(bool) setFault}) build(
    _SourcePlayer player, {
    bool transcoding = false,
    bool faultSeen = false,
  }) {
    final reloads = <Duration>[];
    var fault = faultSeen;
    final recovery = SpuriousEofRecovery(
      isLive: false,
      isOffline: () => false,
      isTranscoding: () => transcoding,
      transitionGate: PlaybackTransitionGate(),
      player: () => player,
      metadata: () => testMediaItem(durationMs: durationMs),
      transportFaultSeen: () => fault,
      reload: ({required Duration resumePosition, required String reason}) async {
        reloads.add(resumePosition);
        return MediaReloadOutcome.opened;
      },
      wakelock: WakelockController(platformToggle: (_) async {}),
    );
    return (recovery: recovery, reloads: reloads, setFault: (value) => fault = value);
  }

  test('a short EOF on a sized direct-play file with no transport fault is the real end', () async {
    final player = shortEofPlayer();
    addTearDown(player.dispose);
    final (:recovery, :reloads, setFault: _) = build(player);

    expect(await recovery.interceptEof(player), isFalse);
    expect(reloads, isEmpty);
    expect(recovery.parked, isFalse);
  });

  test('a short EOF after any transport fault in this file recovers, then parks (#1520)', () async {
    final player = shortEofPlayer();
    addTearDown(player.dispose);
    final (:recovery, :reloads, setFault: _) = build(player, faultSeen: true);

    for (var attempt = 0; attempt < SpuriousEofRecovery.maxAttempts; attempt++) {
      expect(await recovery.interceptEof(player), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(reloads, hasLength(attempt + 1));
      expect(recovery.parked, isFalse);
    }
    expect(await recovery.interceptEof(player), isTrue);
    expect(reloads, hasLength(SpuriousEofRecovery.maxAttempts));
    expect(recovery.parked, isTrue);
  });

  test('a fault delivered while the source is being read still explains the EOF', () async {
    // mpv hands property changes to the client ahead of queued log lines, so
    // the "Stream ends prematurely" behind an EOF can land after it.
    final player = shortEofPlayer();
    addTearDown(player.dispose);
    final (:recovery, :reloads, :setFault) = build(player);
    player.onRead = () => setFault(true);

    expect(await recovery.interceptEof(player), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(reloads, [const Duration(milliseconds: positionMs)]);
  });

  test('an unsized or empty source keeps the duration rule', () async {
    for (final size in [null, 0]) {
      final player = shortEofPlayer(fileSize: size);
      addTearDown(player.dispose);
      final (:recovery, :reloads, setFault: _) = build(player);

      expect(await recovery.interceptEof(player), isTrue, reason: 'file-size $size');
      await Future<void>.delayed(Duration.zero);
      expect(reloads, [const Duration(milliseconds: positionMs)], reason: 'file-size $size');
    }
  });

  test('a manifest played directly keeps the duration rule', () async {
    // A `.strm` pointing at an HLS playlist: mpv sizes the manifest, but the
    // segments behind it fail under a prefix the fault latch does not watch.
    final player = shortEofPlayer(fileFormat: 'hls');
    addTearDown(player.dispose);
    final (:recovery, :reloads, setFault: _) = build(player);

    expect(await recovery.interceptEof(player), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(reloads, [const Duration(milliseconds: positionMs)]);
  });

  test('a transcode keeps the duration rule', () async {
    final player = shortEofPlayer();
    addTearDown(player.dispose);
    final (:recovery, :reloads, setFault: _) = build(player, transcoding: true);

    expect(await recovery.interceptEof(player), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(reloads, [const Duration(milliseconds: positionMs)]);
  });

  test('a source read that fails keeps the duration rule', () async {
    final player = shortEofPlayer();
    addTearDown(player.dispose);
    final (:recovery, :reloads, setFault: _) = build(player);
    player.onRead = () => throw StateError('channel gone');

    expect(await recovery.interceptEof(player), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(reloads, [const Duration(milliseconds: positionMs)]);
  });

  group('isTransportFaultLog', () {
    PlayerLog log(String prefix, PlayerLogLevel level) => PlayerLog(prefix: prefix, level: level, text: 'x');

    test('libav protocol warnings and errors count', () {
      expect(SpuriousEofRecovery.isTransportFaultLog(log('ffmpeg', PlayerLogLevel.warn)), isTrue);
      expect(SpuriousEofRecovery.isTransportFaultLog(log('ffmpeg', PlayerLogLevel.error)), isTrue);
    });

    test('decoder, demuxer, and informational lines do not', () {
      expect(SpuriousEofRecovery.isTransportFaultLog(log('ffmpeg/video', PlayerLogLevel.warn)), isFalse);
      expect(SpuriousEofRecovery.isTransportFaultLog(log('ffmpeg/demuxer', PlayerLogLevel.error)), isFalse);
      expect(SpuriousEofRecovery.isTransportFaultLog(log('ffmpeg', PlayerLogLevel.info)), isFalse);
      expect(SpuriousEofRecovery.isTransportFaultLog(log('cplayer', PlayerLogLevel.error)), isFalse);
    });
  });
}
