import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../utils/app_logger.dart';
import '../device_adjustment_service.dart';
import 'music_output_controller.dart';
import 'music_playback_service.dart';

/// Lets the phone's volume buttons change a speaker in another room.
///
/// ### Why this is indirect
///
/// iOS gives an app no key events for the volume buttons. The only supported
/// signal is that the system output volume changed, so the buttons are read by
/// watching that value — and to read a *second* press in the same direction,
/// the system volume has to be put back where it was. It is therefore pinned
/// mid-scale while a speaker is selected, which also stops the handset's own
/// level drifting to an extreme during a long listening session.
///
/// Pinning also means iOS's own volume pop-up has nothing true to show — it
/// would report the handset bouncing around mid-scale — so the hidden system
/// slider suppresses it and [lastPress] carries the speaker's level for the
/// app to show instead.
///
/// ### Why it is off most of the time
///
/// Pinning is a real side effect on the device's own audio, so it only runs
/// while the chosen output is one the buttons cannot otherwise reach. Playing
/// on the phone they keep their ordinary meaning, untouched.
class RemoteVolumeButtons {
  /// Private-named formals: callers pass `outputs:` and `playback:`.
  RemoteVolumeButtons({required this._outputs, required this._playback, DeviceAdjustmentService? device})
    : _device = device ?? DeviceAdjustmentService.instance;

  /// Where the system volume is held while a speaker is selected. Mid-scale so
  /// there is room to detect a press in either direction.
  static const double pinnedSystemVolume = 0.5;

  /// Below this, a reported change is the pin being restored rather than a
  /// press. iOS reports the volume in steps of about 1/16.
  static const double _pressThreshold = 0.01;

  /// How long a sent level stays the base for the next press. A burst of
  /// presses lands faster than the speaker reports back, so reading
  /// [MusicPlaybackService.volume] for each would drop all but the first.
  static const Duration _burstWindow = Duration(seconds: 2);

  final MusicOutputController _outputs;
  final MusicPlaybackService _playback;
  final DeviceAdjustmentService _device;

  bool _watching = false;
  bool _restoring = false;

  /// Whether the last pin took. While it has not — at launch iOS has no
  /// window to host its volume slider yet — presses are measured from the last
  /// reading instead of from [pinnedSystemVolume], or the first one would move
  /// the speaker by however far the phone happened to be from mid-scale.
  bool _pinned = false;
  double _lastSeen = pinnedSystemVolume;

  double? _sentLevel;
  DateTime? _sentAt;

  final ValueNotifier<RemoteVolumePress?> _lastPress = ValueNotifier<RemoteVolumePress?>(null);

  /// The most recent press, for an on-screen level indicator. Each press is a
  /// new value even when the level is unchanged, so pressing at either end
  /// still shows the limit.
  ValueListenable<RemoteVolumePress?> get lastPress => _lastPress;

  /// Begin following the output selection. Safe to call more than once.
  void start() {
    _outputs.addListener(_syncToSelection);
    _syncToSelection();
  }

  Future<void> dispose() async {
    _outputs.removeListener(_syncToSelection);
    await _stop();
    _lastPress.dispose();
  }

  bool get isWatching => _watching;

  void _syncToSelection() {
    final output = _outputs.selected;
    final wanted = output.isRemote && output.supportsVolume;
    if (wanted == _watching) return;
    unawaited(wanted ? _begin() : _stop());
  }

  Future<void> _begin() async {
    _watching = true;
    _device.onSystemVolumeChanged = _onSystemVolume;
    await _device.startVolumeButtonWatch();
    _lastSeen = await _device.getMediaVolume() ?? pinnedSystemVolume;
    await _pin();
    appLogger.d('Volume buttons now drive ${_outputs.selected.name}');
  }

  Future<void> _stop() async {
    if (!_watching) return;
    _watching = false;
    _sentLevel = null;
    _device.onSystemVolumeChanged = null;
    await _device.stopVolumeButtonWatch();
  }

  Future<void> _pin() async {
    _restoring = true;
    // Assumed to take until told otherwise: the restored value can come back
    // before the call does, and must read as the pin, not as a press.
    _pinned = true;
    try {
      _pinned = await _device.setMediaVolume(pinnedSystemVolume);
    } finally {
      // Cleared on the next turn: the change we just made comes back through
      // the same callback, and treating it as a press would double every step.
      scheduleMicrotask(() => _restoring = false);
    }
  }

  void _onSystemVolume(double value) {
    if (!_watching || _restoring) return;
    final reference = _pinned ? pinnedSystemVolume : _lastSeen;
    _lastSeen = value;
    final delta = value - reference;
    if (delta.abs() < _pressThreshold) return;

    // The press is a direction and a size, applied to whatever the speaker is
    // at now — not an absolute position, because the two scales are unrelated.
    final now = DateTime.now();
    final sentAt = _sentAt;
    final inBurst = _sentLevel != null && sentAt != null && now.difference(sentAt) < _burstWindow;
    final base = inBurst ? _sentLevel! : _playback.volume;
    final next = (base + delta * 100).clamp(0.0, 100.0).toDouble();
    _sentLevel = next;
    _sentAt = now;
    _lastPress.value = RemoteVolumePress(outputName: _outputs.selected.name, level: next);
    unawaited(_playback.setVolume(next));
    unawaited(_pin());
  }
}

/// One forwarded press: which speaker, and the level (0–100) it was sent to.
@immutable
class RemoteVolumePress {
  const RemoteVolumePress({required this.outputName, required this.level});

  final String outputName;
  final double level;
}
