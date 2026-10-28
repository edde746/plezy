import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/games/game_models.dart';
import 'package:plezy/games/steam_stream_preferences.dart';
import 'package:plezy/multiview/steam_game_workspace_surface.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/prefs.dart';

void main() {
  setUp(() {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
  });

  test('quality is profile scoped and unknown persisted values preserve legacy defaults', () async {
    final settings = await SettingsService.getInstance();
    final quality = SettingsService.steamQualityForProfile('one');
    await settings.write(quality, SteamStreamQuality.reducedBandwidth);
    expect(settings.read(quality), SteamStreamQuality.reducedBandwidth);
    expect(settings.read(SettingsService.steamQualityForProfile('two')), SteamStreamQuality.balanced);
    await settings.prefs.setString(quality.key, 'unknown-future-quality');
    expect(settings.read(quality), SteamStreamQuality.balanced);
  });

  test('profile preferences reach native creation with no credentials', () {
    final host = GameHost(id: '123', name: 'Desktop', address: 'desktop.local', protocol: GameProtocol.steam);
    final session = SteamGameWorkspaceSession(
      host: host,
      game: StreamGame(hostKey: host.key, id: '620', name: 'Portal 2'),
      touchControls: false,
      quality: SteamStreamQuality.reducedBandwidth,
      codec: SteamStreamCodec.h264,
    );
    addTearDown(session.dispose);
    expect(session.creationParams, containsPair('streamWidth', 1280));
    expect(session.creationParams, containsPair('streamHeight', 720));
    expect(session.creationParams, containsPair('streamFps', 60));
    expect(session.creationParams, containsPair('streamBitrateKbps', 12000));
    expect(session.creationParams, containsPair('allowHevc', false));
    expect(session.creationParams.keys, isNot(contains('key')));
  });
}
