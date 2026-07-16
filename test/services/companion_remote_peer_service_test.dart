import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/models/companion_remote/remote_command.dart';
import 'package:plezy/services/companion_remote/companion_remote_peer_service.dart';
import 'package:plezy/services/companion_remote/remote_auth_context.dart';

void main() {
  test('auth precondition error uses the active locale', () async {
    await LocaleSettings.setLocale(AppLocale.bg);
    addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));
    final peer = CompanionRemotePeerService();
    addTearDown(peer.dispose);

    await expectLater(
      () => peer.createSessionForContexts('Test Host', 'macos', const []),
      throwsA(isA<PeerError>().having((error) => error.message, 'message', 'Неуспешно удостоверяване')),
    );
  });

  test('host and remote dispatch encrypted commands through the same contract', () async {
    final host = CompanionRemotePeerService();
    final remote = CompanionRemotePeerService();
    addTearDown(() async {
      await remote.dispose();
      await host.dispose();
    });

    final context = RemoteAuthContext(
      id: 'context-1',
      backend: 'plex',
      connectionId: 'connection-1',
      homeSecret: List<int>.generate(32, (index) => index),
      discoveryKey: List<int>.generate(32, (index) => 255 - index),
      clientIdentifier: 'host-client',
      userUuid: 'user-1',
      allowedUserUuids: const ['user-1'],
    );

    final session = await host.createSessionForContexts('Test Host', 'macos', [context]);
    await remote.joinSessionWithContexts(
      'Test Remote',
      'ios',
      '127.0.0.1:${session.port}',
      [context],
      authContextId: context.id,
      expectedHostClientId: context.clientIdentifier,
    );

    final hostCommand = host.onCommandReceived.firstWhere((command) => command.type == RemoteCommandType.play);
    remote.sendCommand(const RemoteCommand(type: RemoteCommandType.play, data: {'source': 'remote'}));
    expect(
      await hostCommand.timeout(const Duration(seconds: 5)),
      const RemoteCommand(type: RemoteCommandType.play, data: {'source': 'remote'}),
    );

    final remoteCommand = remote.onCommandReceived.firstWhere((command) => command.type == RemoteCommandType.pause);
    host.sendCommand(const RemoteCommand(type: RemoteCommandType.pause, data: {'source': 'host'}));
    expect(
      await remoteCommand.timeout(const Duration(seconds: 5)),
      const RemoteCommand(type: RemoteCommandType.pause, data: {'source': 'host'}),
    );
  });
}
