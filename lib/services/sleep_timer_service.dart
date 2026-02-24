import 'dart:async';
import 'package:flutter/foundation.dart';
import '../utils/app_logger.dart';

/// Service to manage sleep timer functionality
/// Allows setting a timer to pause/stop playback after a specified duration
class SleepTimerService extends ChangeNotifier {
  static final SleepTimerService _instance = SleepTimerService._internal();
  factory SleepTimerService() => _instance;
  SleepTimerService._internal();

  Timer? _timer;
  DateTime? _endTime;
  Duration? _duration;
  Duration? _originalDuration;
  VoidCallback? _onTimerComplete;
  bool _needsRestart = false;
  final StreamController<void> _completedController = StreamController<void>.broadcast();
  final StreamController<void> _promptController = StreamController<void>.broadcast();

  /// Emits when the sleep timer completes (not when cancelled)
  Stream<void> get onCompleted => _completedController.stream;

  /// Emits when the timer fires and wants to show a "still watching?" prompt
  Stream<void> get onPrompt => _promptController.stream;

  /// Whether a timer is currently active
  bool get isActive => _timer != null && _timer!.isActive;

  /// The time when the timer will complete
  DateTime? get endTime => _endTime;

  /// The original duration of the timer
  Duration? get duration => _duration;

  /// The user-selected duration (unmodified by extendTimer)
  Duration? get originalDuration => _originalDuration;

  /// Remaining time on the timer
  Duration? get remainingTime {
    if (_endTime == null) return null;
    final remaining = _endTime!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Start a sleep timer with the specified duration
  /// [duration] - How long until the timer completes
  /// [onComplete] - Callback to execute when timer completes
  void startTimer(Duration duration, VoidCallback onComplete) {
    // Cancel any existing timer
    cancelTimer();

    _originalDuration = duration;
    _duration = duration;
    _endTime = DateTime.now().add(duration);
    _onTimerComplete = onComplete;

    appLogger.d('Sleep timer started: ${duration.inMinutes} minutes');

    // Create a periodic timer to update remaining time
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = remainingTime;

      if (remaining == null || remaining.inSeconds <= 0) {
        appLogger.d('Sleep timer completed - showing prompt');
        _stopTimerOnly();
        _promptController.add(null);
      } else {
        // Notify listeners to update UI
        notifyListeners();
      }
    });

    notifyListeners();
  }

  /// Cancel the active timer (user-initiated, clears everything)
  void cancelTimer() {
    if (_timer != null || _originalDuration != null) {
      appLogger.d('Sleep timer cancelled');
      _timer?.cancel();
      _timer = null;
      _endTime = null;
      _duration = null;
      _originalDuration = null;
      _onTimerComplete = null;
      notifyListeners();
    }
  }

  /// Restart the timer with the original user-selected duration
  void restartTimer() {
    if (_originalDuration != null && _onTimerComplete != null) {
      final duration = _originalDuration!;
      final callback = _onTimerComplete!;
      startTimer(duration, callback);
    }
  }

  /// Execute the completion callback directly (fallback path)
  void executeCompletion() {
    _executeCallback();
  }

  /// Mark that the timer should restart when a new playback session begins
  /// (e.g. user exited the player and started something new)
  void markNeedsRestart() {
    if (isActive || _originalDuration != null) {
      _needsRestart = true;
    }
  }

  /// Restart the timer if it was marked for restart (new playback session).
  /// [onComplete] provides the new callback for the fresh session.
  void restartIfNeeded(VoidCallback onComplete) {
    if (_needsRestart && _originalDuration != null) {
      _needsRestart = false;
      startTimer(_originalDuration!, onComplete);
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

  /// Stop the periodic timer but preserve _originalDuration and _onTimerComplete
  /// for the prompt flow (restart/completion)
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
    _completedController.close();
    _promptController.close();
    super.dispose();
  }
}
