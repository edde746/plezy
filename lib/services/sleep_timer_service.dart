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
  VoidCallback? _onTimerComplete;
  final StreamController<void> _completedController = StreamController<void>.broadcast();

  /// Emits when the sleep timer completes (not when cancelled)
  Stream<void> get onCompleted => _completedController.stream;

  /// Whether a timer is currently active
  bool get isActive => _timer != null && _timer!.isActive;

  /// The time when the timer will complete
  DateTime? get endTime => _endTime;

  /// The original duration of the timer
  Duration? get duration => _duration;

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

    _duration = duration;
    _endTime = DateTime.now().add(duration);
    _onTimerComplete = onComplete;

    appLogger.d('Sleep timer started: ${duration.inMinutes} minutes');

    // Create a periodic timer to update remaining time
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = remainingTime;

      if (remaining == null || remaining.inSeconds <= 0) {
        appLogger.d('Sleep timer completed');
        _executeCallback();
        cancelTimer();
      } else {
        // Notify listeners to update UI
        notifyListeners();
      }
    });

    notifyListeners();
  }

  /// Cancel the active timer
  void cancelTimer() {
    if (_timer != null) {
      appLogger.d('Sleep timer cancelled');
      _timer?.cancel();
      _timer = null;
      _endTime = null;
      _duration = null;
      _onTimerComplete = null;
      notifyListeners();
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
    super.dispose();
  }
}
