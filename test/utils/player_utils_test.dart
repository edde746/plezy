import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/mpv.dart' show Player, PlayerState;
import 'package:plezy/utils/player_utils.dart';

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
}

class _FakePlayer implements Player {
  _FakePlayer({required Duration duration}) : _state = PlayerState(duration: duration);

  final PlayerState _state;

  @override
  PlayerState get state => _state;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
