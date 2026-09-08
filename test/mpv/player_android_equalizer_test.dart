import 'package:plezy/models/audio_equalizer.dart';
import 'package:plezy/mpv/models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/player/platform/player_android.dart';
import 'package:plezy/services/settings_service.dart';
import '../test_helpers/mock_player_channels.dart';
import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    resetSharedPreferencesForTest();
    await SettingsService.getInstance();
  });
  test('Android retains pre-initialization EQ and clears the fallback filter on disable', () async {
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
          await player.setAudioEqualizer(EqualizerProfile(preampDb: -2, bassDb: 3));
          await player.open(Media('https://example.test/audio.mp4'));
          final initEq = calls.lastWhere((c) => c.method == 'setAudioEqualizer').arguments as Map;
          expect(initEq['preampDb'], -2);
          expect(initEq['bassDb'], 3);
          expect(initEq['filter'], contains('volume=-2.0dB'));
          expect(initEq['filter'], contains('equalizer=f=80:t=q:w=0.5:g=3.0'));
          await player.setAudioEqualizer(EqualizerProfile.flat);
          final off = calls.lastWhere((c) => c.method == 'setAudioEqualizer').arguments as Map;
          expect(off['gains'], EqualizerProfile.flatGains);
          expect(off['filter'], isEmpty);
          expect(off['preampDb'], 0);
        } finally {
          await player.dispose();
        }
      },
    );
  });
}
