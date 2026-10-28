import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'visualizer_pack_store.dart';

class VisualizerCapabilities {
  const VisualizerCapabilities({required this.available, required this.reason, this.engine = ''});
  final bool available;
  final String reason;
  final String engine;
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
  String _state = 'idle', _reason = '';
  bool _hasFrame = false;
  VisualizerPresetFile? _preset;

  int? get textureId => _textureId;
  VisualizerPresetFile? get preset => _preset;
  String get state => _state;
  String get reason => _reason;
  bool get hasFrame => _hasFrame && (_state == 'rendering' || _state == 'paused');
  bool get active => _preset != null;
  String get statusLabel => switch (_state) {
    'loading' || 'starting' => 'Loading preset…',
    'rendering' => 'Live music audio · projectM',
    'paused' => 'Visualization paused',
    'waiting-audio' => 'Waiting for music audio',
    'failed' || 'unavailable' => _reason,
    _ => '',
  };

  static Future<VisualizerCapabilities> capabilities() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.linux) {
      return const VisualizerCapabilities(
        available: false,
        reason: 'Native preset playback is not available on this platform yet.',
      );
    }
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('visualizerCapabilities');
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
    if (!preset.supportsProjectM) throw StateError('MilkDrop 3 double presets are stored, but are not playable by this renderer.');
    // A failed native worker has exited. Retry with a new worker and GL context.
    if (_state == 'failed' || _state == 'unavailable') await _release();
    _preset = preset;
    _state = 'loading'; _reason = ''; _hasFrame = false;
    _changed();
    if (_sessionId == null) {
      final capability = await capabilities();
      if (_closed) return;
      if (!capability.available) {
        _state = 'unavailable'; _reason = capability.reason; _changed(); return;
      }
      final result = await _channel.invokeMapMethod<String, dynamic>('visualizerCreate');
      _sessionId = result?['sessionId'] as int?;
      _textureId = result?['textureId'] as int?;
      if (_sessionId == null || _textureId == null) throw StateError('The native renderer did not create a texture.');
      if (_closed) return; // dispose is queued and owns the new lease.
    }
    await _call<void>('visualizerResize', {'width': _width, 'height': _height});
    await _call<void>('visualizerLoad', {'path': preset.path, 'root': preset.root});
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
        if (_state != state || _reason != reason || _hasFrame != hasFrame) {
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
