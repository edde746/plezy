import 'dart:async';
import 'package:flutter/foundation.dart';
import '../utils/app_logger.dart';

/// Service to manage sleep timer functionality
/// Allows setting a timer to pause/stop playback after a specified duration
class SleepTimerService extends ChangeNotifier {
  static final SleepTimerService _instance = SleepTimerService._internal();
  factory SleepTimerService() => _instance;
  SleepTimerService._internal() : _now = DateTime.now;

  @visibleForTesting
  SleepTimerService.withClock(DateTime Function() now) : _now = now;
  final DateTime Function() _now;

  Timer? _timer;
  DateTime? _endTime;
  Duration? _duration;
  Duration? _originalDuration;
  Object? _playbackOwner;
  VoidCallback? _onTimerComplete;
  bool _needsRestart = false;
  bool _restartAsEndOfVideo = false;
  bool _endOfVideoArmed = false;
  final StreamController<void> _completedController = StreamController<void>.broadcast();
  final StreamController<void> _promptController = StreamController<void>.broadcast();

  /// Emits when the sleep timer completes (not when cancelled)
  Stream<void> get onCompleted => _completedController.stream;

  /// Emits when the timer fires and wants to show a "still watching?" prompt
  Stream<void> get onPrompt => _promptController.stream;

  bool get isActive => (_timer != null && _timer!.isActive) || _endOfVideoArmed;

  /// Whether the sleep timer is armed to fire at the end of the current video
  /// rather than after a fixed duration.
  bool get isEndOfVideoMode => _endOfVideoArmed;

  /// The time when the timer will complete
  DateTime? get endTime => _endTime;

  /// The original duration of the timer
  Duration? get duration => _duration;

  /// The user-selected duration (unmodified by extendTimer)
  Duration? get originalDuration => _originalDuration;

  /// Remaining time on the timer
  Duration? get remainingTime {
    if (_endTime == null) return null;
    final remaining = _endTime!.difference(_now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Replace the playback target without changing the selected timer or deadline.
  void bindPlayback({required Object owner, required VoidCallback onComplete}) {
    _playbackOwner = owner;
    _onTimerComplete = onComplete;
  }

  /// Release the current playback target and restart its timer on the next session.
  /// A superseded owner cannot detach its successor or restart the countdown.
  void unbindPlayback(Object owner) {
    if (!identical(_playbackOwner, owner)) return;

    _playbackOwner = null;
    _onTimerComplete = null;
    if (isActive || _originalDuration != null) {
      _needsRestart = true;
      _restartAsEndOfVideo = _endOfVideoArmed;
    }
  }

  void startTimer(Duration duration) {
    cancelTimer();

    _originalDuration = duration;
    _duration = duration;
    _endTime = _now().add(duration);

    appLogger.d('Sleep timer started: ${duration.inMinutes} minutes');

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = remainingTime;

      if (remaining == null || remaining.inSeconds <= 0) {
        appLogger.d('Sleep timer completed - showing prompt');
        _stopTimerOnly();
        _promptController.add(null);
      } else {
        notifyListeners();
      }
    });

    notifyListeners();
  }

  /// Arm the sleep timer to fire when the currently playing video reaches its end.
  /// Unlike [startTimer], no periodic timer runs — playback completion is reported
  /// externally via [notifyVideoCompleted].
  void armEndOfVideo() {
    cancelTimer();

    _endOfVideoArmed = true;

    appLogger.d('Sleep timer armed: end of current video');
    notifyListeners();
  }

  /// Notify the service that the currently playing video has completed.
  /// If armed via [armEndOfVideo], fires the completion callback and resets the mode.
  /// Safe to call unconditionally — does nothing when end-of-video mode is not armed.
  void notifyVideoCompleted() {
    if (!_endOfVideoArmed) return;

    appLogger.d('Sleep timer (end of video) triggered');
    _endOfVideoArmed = false;
    _executeCallback();
    notifyListeners();
  }

  /// Cancel the timer configuration and pending restart, keeping playback bound.
  void cancelTimer() {
    if (_timer != null || _originalDuration != null || _endOfVideoArmed || _needsRestart || _restartAsEndOfVideo) {
      appLogger.d('Sleep timer cancelled');
      _timer?.cancel();
      _timer = null;
      _endTime = null;
      _duration = null;
      _originalDuration = null;
      _needsRestart = false;
      _endOfVideoArmed = false;
      _restartAsEndOfVideo = false;
      notifyListeners();
    }
  }

  void restartTimer() {
    if (_originalDuration != null) {
      startTimer(_originalDuration!);
    }
  }

  /// Restart the timer if it was marked for restart (new playback session).
  void restartIfNeeded() {
    if (!_needsRestart) return;
    _needsRestart = false;

    if (_restartAsEndOfVideo) {
      _restartAsEndOfVideo = false;
      armEndOfVideo();
    } else if (_originalDuration != null) {
      startTimer(_originalDuration!);
    }
  }

  /// Extend the current timer by the specified duration
  void extendTimer(Duration additionalTime) {
    if (_endTime != null) {
      _endTime = _endTime!.add(additionalTime);
      _duration = _duration != null ? _duration! + additionalTime : additionalTime;
      appLogger.d('Sleep timer extended by ${additionalTime.inMinutes} minutes');
      notifyListeners();
    }
  }

  /// Stop the countdown but preserve the selection and playback binding for
  /// the still-watching prompt's restart flow.
  void _stopTimerOnly() {
    _timer?.cancel();
    _timer = null;
    _endTime = null;
    _duration = null;
    notifyListeners();
  }

  void _executeCallback() {
    if (_onTimerComplete != null) {
      try {
        _onTimerComplete!();
      } catch (e) {
        appLogger.e('Error executing sleep timer callback', error: e);
      }
    }
    _completedController.add(null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _playbackOwner = null;
    _onTimerComplete = null;
    _completedController.close();
    _promptController.close();
    super.dispose();
  }
}
