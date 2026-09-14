import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/player/platform/player_android.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/mock_player_channels.dart';
import '../test_helpers/prefs.dart';

/// The ExoPlayer core emits no mpv `speed` property, so [PlayerAndroid.setRate]
/// must mirror the rate it wrote into [PlayerState] itself — exactly as
/// [PlayerAndroid.setVolume] does for volume. Without the mirror the speed
/// sheet's checkmark and the keyboard speed-step shortcuts (which compute from
/// `state.rate`) stay frozen at 1.0 after every rate change.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  Future<void> withPlayer(Future<void> Function(PlayerAndroid player, List<MethodCall> calls) body) async {
    final calls = <MethodCall>[];
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/exo_player',
      eventChannelName: 'com.plezy/exo_player/events',
      methodHandler: (call) async {
        calls.add(call);
        return call.method == 'initialize' ? true : null;
      },
      testBody: () async {
        final player = PlayerAndroid();
        try {
          await body(player, calls);
        } finally {
          await player.dispose();
        }
      },
    );
  }

  test('setRate mirrors the written rate into state and the rate stream', () async {
    await withPlayer((player, calls) async {
      final rates = <double>[];
      final subscription = player.streams.rate.listen(rates.add);
      addTearDown(subscription.cancel);

      expect(player.state.rate, 1.0);
      await player.setRate(2.0);
      await Future<void>.delayed(Duration.zero);

      expect(player.state.rate, 2.0);
      expect(rates, [2.0]);
      final nativeWrite = calls.singleWhere((call) => call.method == 'setRate');
      expect((nativeWrite.arguments as Map)['rate'], 2.0);
    });
  });

  test('repeating the current rate is a state no-op', () async {
    await withPlayer((player, calls) async {
      final rates = <double>[];
      final subscription = player.streams.rate.listen(rates.add);
      addTearDown(subscription.cancel);

      await player.setRate(2.0);
      await player.setRate(2.0);
      await Future<void>.delayed(Duration.zero);

      expect(player.state.rate, 2.0);
      // The native write still happens; only the Dart-side mirror deduplicates,
      // which keeps a backend-echoed `speed` event harmless too.
      expect(calls.where((call) => call.method == 'setRate'), hasLength(2));
      expect(rates, [2.0]);
    });
  });
}
