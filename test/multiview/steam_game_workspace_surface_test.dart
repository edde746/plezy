import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/games/game_models.dart';
import 'package:plezy/multiview/steam_game_workspace_surface.dart';

void main() {
  test('Steam workspace surface arguments stay structured and non-secret', () {
    final host = GameHost(
      id: '76561198000000000',
      name: 'Living room PC',
      address: '192.168.1.10',
      protocol: GameProtocol.steam,
      port: 27036,
    );
    final game = StreamGame(hostKey: host.key, id: '0', name: 'Big Picture');
    final session = SteamGameWorkspaceSession(host: host, game: game, touchControls: false);

    expect(session.creationParams, containsPair('hostId', host.id));
    expect(session.creationParams, containsPair('hostKey', 'steam:${host.id}'));
    expect(session.creationParams, containsPair('address', host.address));
    expect(session.creationParams, containsPair('port', 27036));
    expect(session.creationParams, containsPair('appId', '0'));
    expect(session.creationParams, containsPair('touchControls', false));
    expect(session.creationParams.keys, isNot(contains('password')));
    expect(SteamGameWorkspaceSession.channelNameForViewId(7), 'com.plezy/games/steam_stream/7');
    expect(session.workspaceSurface().key, same(session.workspaceSurface().key));

    session.dispose();
  });
}
