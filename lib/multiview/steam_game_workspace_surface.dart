import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_gamepad/universal_gamepad.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../games/game_models.dart';
import '../games/steam_stream_preferences.dart';
import '../games/steam_stream_metrics.dart';
import '../services/gamepad_service.dart';
import '../screens/games/steam_stream_diagnostics.dart';
import '../utils/dialogs.dart';
import '../widgets/app_icon.dart';
import '../focus/focusable_button.dart';
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
    this.quality = SteamStreamQuality.balanced,
    this.codec = SteamStreamCodec.automatic,
    this.controllerCount = 1,
    this.audio = SteamStreamAudio.stereo,
    this.onFirstFrame,
  }) {
    if (controllerCount < 1 || controllerCount > 4) throw ArgumentError.value(controllerCount, 'controllerCount');
    _inputBinding = WorkspaceGameInputBinding(
      onEvent: handleInput,
      onNativeKeyEvent: handleNativeKey,
      onInputReset: (reason) {
        // The connection event releases that device only; focus/lease changes
        // still neutralize every seat and keyboard key.
        if (reason != WorkspaceGameInputResetReason.controllerDisconnected) resetInput();
      },
    );
  }

  final GameHost host;
  final StreamGame game;
  final bool touchControls;
  final bool pyrowave;
  final SteamStreamQuality quality;
  final SteamStreamCodec codec;
  final int controllerCount;
  final SteamStreamAudio audio;
  final VoidCallback? onFirstFrame;
  bool _reportedFirstFrame = false;
  bool _disposed = false;
  bool _restarting = false;
  int _stateRevision = 0;
  final ValueNotifier<int> surfaceGeneration = ValueNotifier(0);
  final ValueNotifier<String> sessionState = ValueNotifier('connecting');
  MethodChannel? _channel;
  bool _audioEnabled = false;
  bool _inputEnabled = false;
  int _inputSuspensions = 0;
  bool get _canInput => !_disposed && _inputEnabled && _inputSuspensions == 0 && sessionState.value == 'playing';
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
    ...quality.nativeArguments,
    'allowHevc': codec == SteamStreamCodec.automatic,
    'controllerCount': controllerCount,
    'audioChannels': audio.channels,
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
    if (_disposed) return;
    _inputEnabled = enabled;
    final canInput = _canInput;
    _inputBinding.setEnabled(canInput);
    if (!enabled) {
      await _invoke('resetInput');
    }
    await _invoke('setInputEnabled', {'enabled': canInput});
  }

  void handleInput(GamepadEvent event) {
    if (!_canInput) return;
    if (event is GamepadButtonEvent) {
      unawaited(
        _invoke('setControllerDeviceState', {
          'deviceId': event.gamepadId,
          'buttons': {event.button.name: event.pressed},
        }),
      );
    } else if (event is GamepadAxisEvent) {
      if (!event.value.isFinite) return;
      unawaited(
        _invoke('setControllerDeviceState', {
          'deviceId': event.gamepadId,
          'axes': {event.axis.name: event.value},
        }),
      );
    } else if (event is GamepadConnectionEvent && !event.connected) {
      unawaited(_invoke('disconnectController', {'deviceId': event.gamepadId}));
    }
  }

  void handleNativeKey(KeyEvent event) {
    if (!_canInput) return;
    unawaited(
      _invoke('inputKey', {
        'key': event.logicalKey.debugName ?? event.logicalKey.keyLabel,
        'down': event is! KeyUpEvent,
      }),
    );
  }

  void resetInput() {
    unawaited(_invoke('resetInput'));
  }

  /// The desired workspace lease may change while a dialog is open. Restore
  /// only its current value, never a captured lease from a different pane.
  Future<void> withInputSuspended(Future<void> Function() action) async {
    if (_disposed) return;
    _inputSuspensions++;
    _inputBinding.setEnabled(false);
    await _invoke('setInputEnabled', {'enabled': false});
    try {
      if (!_disposed) await action();
    } finally {
      _inputSuspensions--;
      if (!_disposed) {
        _inputBinding.setEnabled(_canInput);
        await _invoke('setInputEnabled', {'enabled': _canInput});
      }
    }
  }

  Future<SteamStreamMetrics?> readMetrics() async {
    final channel = _channel;
    if (_disposed || channel == null || sessionState.value != 'playing') return null;
    try {
      final data = await channel.invokeMapMethod<Object?, Object?>('getStreamMetrics');
      if (_disposed || _channel != channel || data == null) return null;
      return SteamStreamMetrics.fromNative(data);
    } catch (_) {
      return null;
    }
  }

  Widget build() {
    if (!Platform.isAndroid) {
      return ColoredBox(
        color: Colors.black,
        child: Center(child: Text(t.games.engineUnavailable, textAlign: TextAlign.center)),
      );
    }
    return ValueListenableBuilder<int>(
      valueListenable: surfaceGeneration,
      builder: (_, generation, _) => AndroidView(
        key: ValueKey(generation),
        viewType: steamGamePlatformViewType,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: attachPlatformView,
      ),
    );
  }

  /// Stable identity lets the overlay move this surface between its visible
  /// pane and the retained offstage slot without disposing the native stream.
  Widget workspaceSurface() => SteamGameWorkspaceSurface(key: _surfaceKey, session: this);

  void attachPlatformView(int viewId) {
    if (_disposed) return;
    _channel?.setMethodCallHandler(null);
    final channel = MethodChannel(channelNameForViewId(viewId));
    _channel = channel;
    final replayRevision = _stateRevision;
    channel.setMethodCallHandler((call) async {
      if (_disposed || _channel != channel || _restarting) return null;
      if (call.method == 'sessionState') {
        _stateRevision++;
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
            if (!_disposed && !_restarting && _channel == channel && _stateRevision == replayRevision) {
              _stateChanged(state);
            }
          })
          .catchError((Object _) {}),
    );
    unawaited(_invoke('setAudioEnabled', {'enabled': _audioEnabled}));
    unawaited(_invoke('setInputEnabled', {'enabled': _canInput}));
  }

  void _stateChanged(Object? state) {
    if (_disposed ||
        state is! String ||
        !{'connecting', 'playing', 'reconnecting', 'disconnected', 'failed'}.contains(state)) {
      return;
    }
    sessionState.value = state;
    _inputBinding.setEnabled(_canInput);
    unawaited(_invoke('setInputEnabled', {'enabled': _canInput}));
    if (state == 'playing' && !_reportedFirstFrame) {
      _reportedFirstFrame = true;
      onFirstFrame?.call();
    }
    if (state == 'failed' || state == 'disconnected' || state == 'reconnecting') resetInput();
  }

  /// A replacement surface may only start after native teardown acknowledges
  /// termination. Retired profiles and repeated taps cannot restart a stream.
  Future<void> reconnect() async {
    if (_disposed || _restarting || !{'failed', 'disconnected'}.contains(sessionState.value)) return;
    _restarting = true;
    _inputBinding.setEnabled(false);
    resetInput();
    sessionState.value = 'reconnecting';
    try {
      final channel = _channel;
      if (channel != null) await channel.invokeMethod<void>('disconnect').timeout(const Duration(seconds: 6));
      if (_disposed) return;
      detach();
      sessionState.value = 'connecting';
      surfaceGeneration.value++;
    } catch (_) {
      if (!_disposed) sessionState.value = 'failed';
    } finally {
      _restarting = false;
    }
  }

  Future<void> disconnect() async {
    if (_disposed || _restarting) return;
    resetInput();
    _restarting = true;
    _inputBinding.setEnabled(false);
    try {
      await _channel?.invokeMethod<void>('disconnect').timeout(const Duration(seconds: 6));
      if (!_disposed) sessionState.value = 'disconnected';
    } catch (_) {
      if (!_disposed) sessionState.value = 'failed';
    } finally {
      _restarting = false;
    }
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
    unawaited(_invoke('disconnect'));
    _disposed = true;
    _inputBinding.dispose();
    detach();
    sessionState.dispose();
    surfaceGeneration.dispose();
  }
}

class SteamGameWorkspaceSurface extends StatefulWidget {
  const SteamGameWorkspaceSurface({super.key, required this.session});

  final SteamGameWorkspaceSession session;

  @override
  State<SteamGameWorkspaceSurface> createState() => _SteamGameWorkspaceSurfaceState();
}

class _SteamGameWorkspaceSurfaceState extends State<SteamGameWorkspaceSurface> {
  bool _detailsOpen = false;

  Future<void> _showDetails() async {
    if (_detailsOpen) return;
    setState(() => _detailsOpen = true);
    try {
      await widget.session.withInputSuspended(() async {
        if (!mounted) return;
        await showScopedDialog<void>(
          context: context,
          builder: (_) => SteamStreamDiagnostics(readMetrics: widget.session.readMetrics),
        );
      });
    } finally {
      if (mounted) setState(() => _detailsOpen = false);
    }
  }

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
  Widget build(BuildContext context) {
    final session = widget.session;
    if (!Platform.isAndroid) return session.build();
    return Stack(
      fit: StackFit.expand,
      children: [
        session.build(),
        ValueListenableBuilder<String>(
          valueListenable: session.sessionState,
          builder: (context, state, _) {
            if (state == 'playing') return const SizedBox.shrink();
            final recoverable = state == 'failed' || state == 'disconnected';
            return ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        liveRegion: true,
                        child: Text(switch (state) {
                          'failed' => t.games.streamFailed,
                          'disconnected' => t.games.disconnected,
                          'reconnecting' => t.games.reconnecting,
                          _ => t.games.connecting,
                        }, textAlign: TextAlign.center),
                      ),
                      const SizedBox(height: 12),
                      if (recoverable)
                        FocusableButton(
                          onPressed: session.reconnect,
                          child: FilledButton(onPressed: session.reconnect, child: Text(t.games.reconnect)),
                        )
                      else if (state == 'connecting')
                        FocusableButton(
                          onPressed: session.disconnect,
                          child: TextButton(onPressed: session.disconnect, child: Text(t.games.disconnect)),
                        ),
                      const SizedBox(height: 8),
                      Text(t.games.disconnectHelp, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        PositionedDirectional(
          top: 8,
          end: 8,
          child: ValueListenableBuilder<String>(
            valueListenable: session.sessionState,
            builder: (context, state, _) => state != 'playing'
                ? const SizedBox.shrink()
                : FocusableButton(
                    onPressed: _detailsOpen ? null : _showDetails,
                    child: IconButton.filledTonal(
                      tooltip: t.games.streamDetails,
                      onPressed: _detailsOpen ? null : _showDetails,
                      icon: const AppIcon(Symbols.monitoring_rounded),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
