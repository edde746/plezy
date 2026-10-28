import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_gamepad/universal_gamepad.dart';

import '../games/game_models.dart';
import '../i18n/strings.g.dart';
import 'workspace_game_input.dart';

const steamGamePlatformViewType = 'com.plezy/games/steam_stream';

/// One retained Android Steam session. The workspace owns its audio/input
/// leases; the native PlatformView owns the decoder and disconnects on dispose.
class SteamGameWorkspaceSession {
  SteamGameWorkspaceSession({
    required this.host,
    required this.game,
    required this.touchControls,
    this.pyrowave = false,
    this.onFirstFrame,
  }) {
    _inputBinding = WorkspaceGameInputBinding(
      onEvent: handleInput,
      onNativeKeyEvent: handleNativeKey,
      onInputReset: (_) => resetInput(),
    );
  }

  final GameHost host;
  final StreamGame game;
  final bool touchControls;
  final bool pyrowave;
  final VoidCallback? onFirstFrame;
  bool _reportedFirstFrame = false;
  bool _disposed = false;
  final ValueNotifier<String> sessionState = ValueNotifier('connecting');
  MethodChannel? _channel;
  bool _audioEnabled = false;
  bool _inputEnabled = false;
  final Map<String, bool> _buttons = <String, bool>{};
  final Map<String, double> _axes = <String, double>{};
  late final WorkspaceGameInputBinding _inputBinding;
  final GlobalKey _surfaceKey = GlobalKey();

  static String channelNameForViewId(int viewId) => 'com.plezy/games/steam_stream/$viewId';

  Map<String, Object?> get creationParams => {
    'hostId': host.id,
    'hostKey': 'steam:${host.id}',
    'address': host.address,
    'port': host.port,
    'appId': game.id,
    'appName': game.name,
    'touchControls': touchControls,
    'pyrowave': pyrowave,
    'touchLabel': t.games.touchControls,
    'connecting': t.games.connecting,
    'error': t.games.unavailable,
    'disconnected': t.games.disconnected,
  };

  Future<void> setAudioEnabled(bool enabled) async {
    _audioEnabled = enabled;
    await _invoke('setAudioEnabled', {'enabled': enabled});
  }

  Future<void> setInputEnabled(bool enabled) async {
    _inputEnabled = enabled;
    _inputBinding.setEnabled(enabled);
    if (!enabled) {
      _buttons.clear();
      _axes.clear();
      await _invoke('resetInput');
    }
    await _invoke('setInputEnabled', {'enabled': enabled});
  }

  void handleInput(GamepadEvent event) {
    if (!_inputEnabled) return;
    if (event is GamepadButtonEvent) {
      _buttons[event.button.name] = event.pressed;
    } else if (event is GamepadAxisEvent) {
      _axes[event.axis.name] = event.value;
    } else if (event is GamepadConnectionEvent && !event.connected) {
      resetInput();
      return;
    }
    unawaited(_invoke('setControllerState', {'buttons': _buttons, 'axes': _axes}));
  }

  void handleNativeKey(KeyEvent event) {
    if (!_inputEnabled) return;
    unawaited(
      _invoke('inputKey', {
        'key': event.logicalKey.debugName ?? event.logicalKey.keyLabel,
        'down': event is! KeyUpEvent,
      }),
    );
  }

  void resetInput() {
    _buttons.clear();
    _axes.clear();
    unawaited(_invoke('resetInput'));
  }

  Widget build() {
    if (!Platform.isAndroid) {
      return ColoredBox(
        color: Colors.black,
        child: Center(child: Text(t.games.engineUnavailable, textAlign: TextAlign.center)),
      );
    }
    return AndroidView(
      viewType: steamGamePlatformViewType,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _attach,
    );
  }

  /// Stable identity lets the overlay move this surface between its visible
  /// pane and the retained offstage slot without disposing the native stream.
  Widget workspaceSurface() => SteamGameWorkspaceSurface(key: _surfaceKey, session: this);

  void _attach(int viewId) {
    if (_disposed) return;
    _channel?.setMethodCallHandler(null);
    final channel = MethodChannel(channelNameForViewId(viewId));
    _channel = channel;
    channel.setMethodCallHandler((call) async {
      if (call.method == 'sessionState') {
        _stateChanged(call.arguments);
        return null;
      }
      // The native surface renders its own localized inline connection error.
      if (call.method == 'failed') return null;
      throw MissingPluginException('Unknown Steam view callback: ${call.method}');
    });
    // The first frame may precede channel attachment. Replay native state.
    unawaited(
      channel
          .invokeMethod<String>('getSessionState')
          .then((state) {
            if (!_disposed && _channel == channel) _stateChanged(state);
          })
          .catchError((Object _) {}),
    );
    unawaited(_invoke('setAudioEnabled', {'enabled': _audioEnabled}));
    unawaited(_invoke('setInputEnabled', {'enabled': _inputEnabled}));
    unawaited(_invoke('setControllerState', {'buttons': _buttons, 'axes': _axes}));
  }

  void _stateChanged(Object? state) {
    if (_disposed ||
        state is! String ||
        !{'connecting', 'playing', 'reconnecting', 'disconnected', 'failed'}.contains(state)) {
      return;
    }
    sessionState.value = state;
    if (state == 'playing' && !_reportedFirstFrame) {
      _reportedFirstFrame = true;
      onFirstFrame?.call();
    }
    if (state == 'failed' || state == 'disconnected' || state == 'reconnecting') resetInput();
  }

  Future<void> _invoke(String method, [Map<String, Object?> arguments = const {}]) async {
    final channel = _channel;
    if (channel == null) return;
    try {
      await channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      // The native view may have been removed while an ownership callback was queued.
    } on PlatformException {
      // A disposed or reconnecting native surface cannot accept a stale lease update.
    }
  }

  void detach() {
    _channel?.setMethodCallHandler(null);
    _channel = null;
  }

  void dispose() {
    if (_disposed) return;
    resetInput();
    _disposed = true;
    _inputBinding.dispose();
    detach();
    sessionState.dispose();
  }
}

class SteamGameWorkspaceSurface extends StatefulWidget {
  const SteamGameWorkspaceSurface({super.key, required this.session});

  final SteamGameWorkspaceSession session;

  @override
  State<SteamGameWorkspaceSurface> createState() => _SteamGameWorkspaceSurfaceState();
}

class _SteamGameWorkspaceSurfaceState extends State<SteamGameWorkspaceSurface> {
  @override
  void didUpdateWidget(covariant SteamGameWorkspaceSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) oldWidget.session.detach();
  }

  @override
  void dispose() {
    // A workspace may unmount inactive panes while another is fullscreen.
    // Keep the session's input registration alive so it can be remounted.
    widget.session.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.session.build();
}
