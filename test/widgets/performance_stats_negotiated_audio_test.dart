import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/player/player_native.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/widgets/video_controls/widgets/performance_overlay/performance_stats.dart';
import 'package:plezy/widgets/video_controls/widgets/performance_overlay/performance_stats_service.dart';

import '../test_helpers/mock_player_channels.dart';
import '../test_helpers/prefs.dart';

final class _PropertyStubPlayer extends PlayerNative {
  _PropertyStubPlayer(this.properties);

  final Map<String, String?> properties;

  @override
  Future<String?> getProperty(String name) async => properties[name];
}

const _base = {
  'audio-codec-name': 'eac3',
  'audio-params/samplerate': '48000',
  'audio-params/hr-channels': '5.1',
  'audio-out-params/samplerate': '48000',
  'audio-out-params/format': 's16',
};

Future<PerformanceStats> _collect(Map<String, String?> properties) async {
  final player = _PropertyStubPlayer(properties);
  late final PerformanceStats stats;
  await withMockPlayerChannels(
    methodChannelName: 'com.plezy/mpv_player',
    eventChannelName: 'com.plezy/mpv_player_events',
    testBody: () async {
      final service = PerformanceStatsService(player);
      final next = service.statsStream.first;
      service.startPolling();
      stats = await next.timeout(const Duration(seconds: 5));
      service.stopPolling();
      service.dispose();
    },
  );
  return stats;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  // Both cases fail if the output fields are sourced from `audio-params/*`:
  // the decoded layout reads 5.1 either way, which is how the iOS downmix
  // stayed invisible in the overlay.
  test('a downmix ahead of the output driver is visible in the stats', () async {
    final stats = await _collect({..._base, 'current-ao': 'audiounit', 'audio-out-params/hr-channels': 'stereo'});

    expect(stats.audioChannels, '5.1', reason: 'the decoder still reports the source layout');
    expect(stats.audioOutChannels, 'stereo');
    expect(stats.audioOutputDriver, 'audiounit');
  });

  test('a layout that survives to the output driver is reported intact', () async {
    final stats = await _collect({..._base, 'current-ao': 'avfoundation', 'audio-out-params/hr-channels': '5.1'});

    expect(stats.audioOutChannels, '5.1');
    expect(stats.audioOutputDriver, 'avfoundation');
    expect(stats.audioOutputFormatted, '5.1 (s16, 48.0 kHz)');
  });
}
