import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'visualizer_pack_store.dart';

class VisualizerCapabilities {
  const VisualizerCapabilities({required this.available, required this.reason, this.engine = ''});
  final bool available;
  final String reason;
  final String engine;
  bool accepts(VisualizerPresetFile preset) => preset.supportsProjectM ||
      (engine.startsWith('milkrust') && preset.path.toLowerCase().endsWith('.milk2'));
}

/// Control and diagnostics only. PCM and pixel buffers stay in the native host.
/// The lease prevents a disposed/hidden widget from modifying a newer session.
class VisualizerSession extends ChangeNotifier {
  static const _channel = MethodChannel('com.plezy/mpv_audio_player');
  Future<void> _tail = Future<void>.value();
  Timer? _poll;
  int? _sessionId;
  int? _textureId;
  bool _closed = false;
  bool _polling = false;
  bool _paused = true;
  int _width = 768, _height = 432;
  double transitionSeconds = 3;
  String _state = 'idle', _reason = '', _engine = 'projectm';
  String get engine => _engine;
  String get engineLabel => _engine == 'milkrust' ? 'MilkRust native' : 'projectM 4.1.8';
  bool accepts(VisualizerPresetFile preset) => preset.supportsProjectM ||
      (_engine == 'milkrust' && preset.path.toLowerCase().endsWith('.milk2'));

  Future<void> setEngine(String engine) => _enqueue(() async {
    if (_closed || _engine == engine) return;
    if (engine != 'projectm' && engine != 'milkrust') throw StateError('Unknown visualization engine.');
    await _release();
    _engine = engine; _preset = null; _state = 'idle'; _reason = ''; _changed();
  });
  bool _hasFrame = false;
  int _droppedFrames = 0, _renderWidth = 0, _renderHeight = 0;
  VisualizerPresetFile? _preset;

  int? get textureId => _textureId;
  VisualizerPresetFile? get preset => _preset;
  String get state => _state;
  String get reason => _reason;
  bool get hasFrame => _hasFrame && (_state == 'rendering' || _state == 'paused');
  bool get active => _preset != null;
  String get diagnostics => [
    'Engine: $engineLabel', 'State: $_state',
    if (_reason.isNotEmpty) _reason,
    if (_renderWidth > 0) 'Render size: $_renderWidth × $_renderHeight',
    'Dropped analysis frames: $_droppedFrames',
    'Native playback and visual fidelity are not yet qualified.',
  ].join('\n\n');
  String get statusLabel => switch (_state) {
    'loading' || 'starting' => 'Loading preset…',
    'rendering' => 'Live music audio · $engineLabel',
    'paused' => 'Visualization paused',
    'waiting-audio' => 'Waiting for music audio',
    'failed' || 'unavailable' => _reason,
    _ => '',
  };

  static Future<VisualizerCapabilities> capabilities({String engine = 'projectm'}) async {
    if (kIsWeb) {
      return const VisualizerCapabilities(
        available: false,
        reason: 'Native preset playback is not available on this platform yet.',
      );
    }
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('visualizerCapabilities', {'engine': engine});
      return VisualizerCapabilities(
        available: result?['available'] == true,
        reason: result?['reason'] as String? ?? 'Native visualization support is unavailable.',
        engine: result?['engine'] as String? ?? '',
      );
    } on MissingPluginException {
      return const VisualizerCapabilities(available: false, reason: 'This build has no native preset renderer.');
    } on PlatformException catch (error) {
      return VisualizerCapabilities(available: false, reason: error.message ?? error.code);
    }
  }

  void _changed() { if (!_closed) notifyListeners(); }

  Future<void> _enqueue(Future<void> Function() action) {
    final operation = _tail.then((_) => action());
    _tail = operation.catchError((Object error) {
      if (_closed) return;
      _state = 'failed';
      _poll?.cancel(); _poll = null;
      _hasFrame = false;
      _reason = error is PlatformException ? error.message ?? error.code : error.toString();
      _changed();
    });
    return _tail;
  }

  Future<T?> _call<T>(String method, [Map<String, Object?> args = const {}]) =>
      _channel.invokeMethod<T>(method, {'sessionId': _sessionId, ...args});

  Future<void> load(VisualizerPresetFile preset) => _enqueue(() async {
    if (_closed) return;
    if (!accepts(preset)) throw StateError('The selected engine does not accept this preset format.');
    // A failed native worker has exited. Retry with a new worker and GL context.
    if (_state == 'failed' || _state == 'unavailable') await _release();
    _preset = preset;
    _state = 'loading'; _reason = ''; _hasFrame = false;
    _changed();
    if (_sessionId == null) {
      final capability = await capabilities(engine: _engine);
      if (_closed) return;
      if (!capability.available) {
        _state = 'unavailable'; _reason = capability.reason; _changed(); return;
      }
      final result = await _channel.invokeMapMethod<String, dynamic>('visualizerCreate', {'engine': _engine});
      _sessionId = result?['sessionId'] as int?;
      _textureId = result?['textureId'] as int?;
      if (_sessionId == null || _textureId == null) throw StateError('The native renderer did not create a texture.');
      if (_closed) return; // dispose is queued and owns the new lease.
    }
    await _call<void>('visualizerResize', {'width': _width, 'height': _height});
    await _call<void>('visualizerLoad', {'path': preset.path, 'root': preset.root,
      'transitionSeconds': transitionSeconds.clamp(0, 10).toDouble()});
    await _call<void>('visualizerSetPaused', {'paused': _paused});
    _poll ??= Timer.periodic(const Duration(milliseconds: 500), (_) => _pollStatus());
    _changed();
  });

  void setPaused(bool paused) {
    if (_closed || _paused == paused) return;
    _paused = paused;
    unawaited(_enqueue(() async {
      if (!_closed && _sessionId != null) await _call<void>('visualizerSetPaused', {'paused': _paused});
    }));
  }

  void resize(double width, double height) {
    if (_closed || !width.isFinite || !height.isFinite) return;
    final w = width.round().clamp(1, 16384).toInt(), h = height.round().clamp(1, 16384).toInt();
    if (_width == w && _height == h) return;
    _width = w; _height = h;
    unawaited(_enqueue(() async {
      if (!_closed && _sessionId != null) await _call<void>('visualizerResize', {'width': _width, 'height': _height});
    }));
  }

  void _pollStatus() {
    if (_closed || _polling || _sessionId == null) return;
    _polling = true;
    unawaited(_enqueue(() async {
      try {
        if (_closed || _sessionId == null) return;
        final status = await _call<Map<dynamic, dynamic>>('visualizerStatus');
        if (_closed || status == null) return;
        final state = status['state'] as String? ?? 'failed';
        final reason = status['reason'] as String? ?? '';
        final hasFrame = status['hasFrame'] == true;
        final dropped = status['droppedFrames'] as int? ?? 0;
        final width = status['width'] as int? ?? 0, height = status['height'] as int? ?? 0;
        if (_state != state || _reason != reason || _hasFrame != hasFrame ||
            _droppedFrames != dropped || _renderWidth != width || _renderHeight != height) {
          _droppedFrames = dropped; _renderWidth = width; _renderHeight = height;
          _state = state; _reason = reason; _hasFrame = hasFrame; _changed();
        }
      } finally { _polling = false; }
    }));
  }

  Future<void> _release() async {
    _poll?.cancel(); _poll = null;
    if (_sessionId != null) {
      try { await _call<void>('visualizerDispose'); }
      on PlatformException catch (error) {
        if (error.code != 'VISUALIZER_STALE') rethrow;
      }
    }
    _sessionId = null; _textureId = null; _hasFrame = false;
    _droppedFrames = 0; _renderWidth = 0; _renderHeight = 0;
  }

  Future<void> stop() => _enqueue(() async {
    await _release();
    _preset = null; _state = 'idle'; _reason = ''; _changed();
  });

  @override
  void dispose() {
    _closed = true;
    _poll?.cancel();
    unawaited(_enqueue(_release));
    super.dispose();
  }
}
