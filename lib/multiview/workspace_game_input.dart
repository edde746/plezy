import '../services/gamepad_service.dart';
import 'workspace_controller.dart';

/// Binds one embedded interactive surface to the workspace's exclusive input
/// lease. Pass [setEnabled] as its
/// [WorkspaceSurfaceRegistration.onInputOwnershipChanged] callback and route
/// [onEvent] to the game's existing input adapter.
///
/// The service's synthesized app-navigation mapping is suspended while this
/// binding owns the controller. Matching Steam Input key mirrors are
/// de-duplicated against raw controller events. Native keys are captured while
/// this binding owns input; provide
/// [onNativeKeyEvent] to route keyboard controls into the game. Without that
/// callback, raw controller events still arrive once and mapped native keys
/// are kept out of app navigation on Windows and Linux. Shift+Escape remains
/// available to release input through the workspace. Use [onInputReset] to release held game
/// controls when focus, the controller connection, or this binding's lease
/// changes.
class WorkspaceGameInputBinding {
  WorkspaceGameInputBinding({required this.onEvent, this.onNativeKeyEvent, this.onInputReset, GamepadService? service})
    : _service = service ?? GamepadService.instance {
    _service.registerWorkspaceInputHandler(this, onEvent, onNativeKeyEvent: onNativeKeyEvent, onReset: onInputReset);
  }

  final GamepadInputEventHandler onEvent;
  final WorkspaceNativeKeyEventHandler? onNativeKeyEvent;
  final GamepadInputResetHandler? onInputReset;
  final GamepadService _service;
  bool _disposed = false;

  /// Enables or releases this game surface's controller lease.
  void setEnabled(bool enabled) {
    if (_disposed) return;
    if (enabled) {
      _service.setWorkspaceInputOwner(this);
    } else {
      _service.releaseWorkspaceInputOwner(this);
    }
  }

  /// Removes the handler and releases it if this surface still owns input.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _service.unregisterWorkspaceInputHandler(this);
  }
}
