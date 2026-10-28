import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/games/game_session_exchange.dart';
import 'package:plezy/games/workspace_game_session_controls.dart';
import 'package:plezy/multiview/workspace_controller.dart';
import 'package:plezy/multiview/workspace_models.dart';

WorkspaceSurfaceRegistration registration(String id, MultiviewMediaKind kind, {VoidCallback? close}) =>
    WorkspaceSurfaceRegistration(
      descriptor: WorkspaceSessionDescriptor(
        id: id,
        title: id,
        kind: kind,
        openedAt: DateTime.utc(2026),
        hasAudio: true,
      ),
      buildSurface: (_) => const SizedBox(),
      onRestore: () {},
      onClose: close,
      onAudioOwnershipChanged: (_) {},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MultiviewWorkspaceController workspace;
  setUp(() {
    workspace = MultiviewWorkspaceController();
  });
  tearDown(() {
    workspace.dispose();
  });

  test('only live game registrations can be listed or disconnected', () async {
    var closed = 0;
    workspace.register(registration('game', MultiviewMediaKind.game, close: () => closed++));
    workspace.register(registration('music', MultiviewMediaKind.music, close: () => fail('not a game')));
    final targets = workspaceGameSessionTargets(workspace);
    expect(targets, hasLength(1));
    expect(await targets.single.execute(GameSessionAction.disconnect), isTrue);
    expect(closed, 1);
    expect(workspace.sessions.single.descriptor.id, 'music');
  });

  test('muting an old game does not mute the selected music session', () async {
    workspace.register(registration('game', MultiviewMediaKind.game));
    workspace.register(registration('music', MultiviewMediaKind.music));
    final game = workspaceGameSessionTargets(workspace).single;
    expect(await game.execute(GameSessionAction.listen), isTrue);
    expect(workspace.audibleSessionId, 'game');
    await workspace.setAudibleSession('music');
    expect(await game.execute(GameSessionAction.mute), isTrue);
    expect(workspace.audibleSessionId, 'music');
    expect(await game.execute(GameSessionAction.disconnect), isFalse); // No close callback.
  });

  test('removed and recreated game registrations invalidate old targets', () async {
    workspace.register(registration('same-game', MultiviewMediaKind.game));
    final original = workspaceGameSessionTargets(workspace).single;
    workspace.unregister('same-game');
    workspace.register(registration('same-game', MultiviewMediaKind.game));
    expect(await original.execute(GameSessionAction.fullscreen), isFalse);
  });
}
