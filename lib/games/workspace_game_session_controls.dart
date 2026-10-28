import '../multiview/workspace_controller.dart';
import '../multiview/workspace_models.dart';
import 'game_session_exchange.dart';

List<GameSessionControlTarget> workspaceGameSessionTargets(MultiviewWorkspaceController? workspace) {
  if (workspace == null) return const [];
  return workspace.sessions
      .where((s) => s.descriptor.kind == MultiviewMediaKind.game)
      .take(8)
      .map((registration) {
        final id = registration.descriptor.id;
        return GameSessionControlTarget(
          owner: registration,
          title: registration.descriptor.title,
          audible: workspace.audibleSessionId == id,
          execute: (action) async {
            // Replaced registrations cannot be controlled through a stale handle.
            if (!workspace.sessions.any((item) => identical(item, registration))) return false;
            switch (action) {
              case GameSessionAction.list:
                return false;
              case GameSessionAction.disconnect:
                // A game session close must disconnect its receiver; never restore
                // an unsupported owner or invoke a host game's quit command.
                if (registration.onClose == null) return false;
                return workspace.close(id);
              case GameSessionAction.fullscreen:
                return workspace.showSessionInWorkspace(id, fullscreen: true);
              case GameSessionAction.listen:
                if (!registration.descriptor.hasAudio) return false;
                await workspace.setAudibleSession(id);
                return workspace.audibleSessionId == id;
              case GameSessionAction.mute:
                await workspace.muteSession(id);
                return workspace.audibleSessionId != id;
            }
          },
        );
      })
      .toList(growable: false);
}
