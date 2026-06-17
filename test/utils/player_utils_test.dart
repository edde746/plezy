import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/mpv/mpv.dart' show BufferRange, Player, PlayerState;
import 'package:vibe_stream/utils/player_utils.dart';

void main() {
  group('shouldRestartBeforePreviousItem', () {
    test('keeps previous item behavior within the restart threshold', () {
      expect(shouldRestartBeforePreviousItem(Duration.zero), isFalse);
      expect(shouldRestartBeforePreviousItem(const Duration(seconds: 3)), isFalse);
    });

    test('restarts the current item after the threshold', () {
      expect(shouldRestartBeforePreviousItem(const Duration(milliseconds: 3001)), isTrue);
    });
  });

  group('clampSeekPosition', () {
    test('clamps negative positions to zero', () {
      final player = _FakePlayer(duration: const Duration(minutes: 5));

      expect(clampSeekPosition(player, const Duration(seconds: -10)), Duration.zero);
    });

    test('clamps positions beyond a known duration', () {
      final player = _FakePlayer(duration: const Duration(minutes: 5));

      expect(clampSeekPosition(player, const Duration(minutes: 6)), const Duration(minutes: 5));
    });

    test('does not upper-clamp when duration is unknown', () {
      final player = _FakePlayer(duration: Duration.zero);

      expect(clampSeekPosition(player, const Duration(minutes: 6)), const Duration(minutes: 6));
    });
  });

  group('resolvePlexTranscodeSeekAction', () {
    test('uses native seek for backward targets inside a local buffer range', () {
      expect(
        resolvePlexTranscodeSeekAction(
          currentPosition: const Duration(seconds: 30),
          target: const Duration(seconds: 20),
          bufferRanges: const [BufferRange(start: Duration(seconds: 10), end: Duration(seconds: 50))],
        ),
        PlexTranscodeSeekAction.nativeSeek,
      );
    });

    test('restarts for backward targets outside local buffer ranges', () {
      expect(
        resolvePlexTranscodeSeekAction(
          currentPosition: const Duration(seconds: 30),
          target: const Duration(seconds: 20),
          bufferRanges: const [BufferRange(start: Duration(seconds: 25), end: Duration(seconds: 50))],
        ),
        PlexTranscodeSeekAction.restartTranscode,
      );
    });

    test('uses native seek for tiny backward or no-op seeks inside the deadband', () {
      expect(
        resolvePlexTranscodeSeekAction(
          currentPosition: const Duration(seconds: 30),
          target: const Duration(milliseconds: 29500),
          bufferRanges: const [],
        ),
        PlexTranscodeSeekAction.nativeSeek,
      );
    });

    test('uses native seek when the target is inside the local buffer range', () {
      expect(
        resolvePlexTranscodeSeekAction(
          currentPosition: const Duration(seconds: 30),
          target: const Duration(seconds: 40),
          bufferRanges: const [BufferRange(start: Duration(seconds: 30), end: Duration(seconds: 50))],
        ),
        PlexTranscodeSeekAction.nativeSeek,
      );
    });

    test('restarts when buffered native seeks are disabled for the active backend', () {
      expect(
        resolvePlexTranscodeSeekAction(
          currentPosition: const Duration(seconds: 30),
          target: const Duration(seconds: 40),
          bufferRanges: const [BufferRange(start: Duration(seconds: 30), end: Duration(seconds: 50))],
          allowBufferedNativeSeek: false,
        ),
        PlexTranscodeSeekAction.restartTranscode,
      );
    });

    test('uses native seek near the start of a buffer range', () {
      expect(
        resolvePlexTranscodeSeekAction(
          currentPosition: const Duration(seconds: 30),
          target: const Duration(milliseconds: 29500),
          bufferRanges: const [BufferRange(start: Duration(seconds: 30), end: Duration(seconds: 50))],
        ),
        PlexTranscodeSeekAction.nativeSeek,
      );
    });

    test('restarts near the tail of a buffer range to avoid optimistic cache edges', () {
      expect(
        resolvePlexTranscodeSeekAction(
          currentPosition: const Duration(seconds: 30),
          target: const Duration(milliseconds: 49600),
          bufferRanges: const [BufferRange(start: Duration(seconds: 30), end: Duration(seconds: 50))],
        ),
        PlexTranscodeSeekAction.restartTranscode,
      );
    });

    test('restarts when a forward target is outside local buffer ranges', () {
      expect(
        resolvePlexTranscodeSeekAction(
          currentPosition: const Duration(seconds: 30),
          target: const Duration(seconds: 58),
          bufferRanges: const [BufferRange(start: Duration(seconds: 30), end: Duration(seconds: 50))],
        ),
        PlexTranscodeSeekAction.restartTranscode,
      );
    });

    test('uses native seek when the target is inside a later cached range', () {
      expect(
        resolvePlexTranscodeSeekAction(
          currentPosition: const Duration(seconds: 5),
          target: const Duration(seconds: 33),
          bufferRanges: const [
            BufferRange(start: Duration(seconds: 0), end: Duration(seconds: 10)),
            BufferRange(start: Duration(seconds: 30), end: Duration(seconds: 35)),
          ],
        ),
        PlexTranscodeSeekAction.nativeSeek,
      );
    });

    test('restarts for gaps far beyond the active range even when a later range exists', () {
      expect(
        resolvePlexTranscodeSeekAction(
          currentPosition: const Duration(seconds: 5),
          target: const Duration(seconds: 25),
          bufferRanges: const [
            BufferRange(start: Duration(seconds: 0), end: Duration(seconds: 10)),
            BufferRange(start: Duration(seconds: 40), end: Duration(seconds: 50)),
          ],
        ),
        PlexTranscodeSeekAction.restartTranscode,
      );
    });

    test('does not treat a flat buffer end as a local seekable range', () {
      expect(
        resolvePlexTranscodeSeekAction(
          currentPosition: const Duration(seconds: 30),
          target: const Duration(seconds: 45),
          bufferRanges: const [],
        ),
        PlexTranscodeSeekAction.restartTranscode,
      );
    });

    test('restarts large seeks when no buffer information exists', () {
      expect(
        resolvePlexTranscodeSeekAction(
          currentPosition: const Duration(seconds: 30),
          target: const Duration(seconds: 35),
          bufferRanges: const [],
        ),
        PlexTranscodeSeekAction.restartTranscode,
      );
    });
  });
}

class _FakePlayer implements Player {
  _FakePlayer({required Duration duration}) : _state = PlayerState(duration: duration);

  final PlayerState _state;

  @override
  PlayerState get state => _state;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
