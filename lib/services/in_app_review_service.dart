import 'dart:async';
import 'dart:io' show Platform;
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';
import 'base_shared_preferences_service.dart';

/// Service to manage in-app review prompts
/// Only enabled when ENABLE_IN_APP_REVIEW build flag is set
class InAppReviewService {
  static final InAppReviewService _instance = InAppReviewService._();
  static InAppReviewService get instance => _instance;

  InAppReviewService._();

  final InAppReview _inAppReview = InAppReview.instance;

  Future<SharedPreferencesWithCache> _getPrefs() => BaseSharedPreferencesService.sharedCache();

  static const String _keyQualifyingSessionsCount = 'review_qualifying_sessions_count';
  static const String _keyLastPromptTime = 'review_last_prompt_time';

  // Configuration
  static const int _requiredSessions = 6;
  static const Duration _minimumSessionDuration = Duration(minutes: 5);
  static const Duration _promptCooldown = Duration(days: 60);

  DateTime? _sessionStartTime;

  static bool get isEnabled {
    if (!Platform.isIOS && !Platform.isAndroid) {
      return false;
    }
    return const bool.fromEnvironment('ENABLE_IN_APP_REVIEW', defaultValue: false);
  }

  void startSession() {
    if (!isEnabled) return;
    _sessionStartTime = DateTime.now();
    appLogger.d('In-app review: Session started');
    // Prompt checks should run while the app is in the foreground.
    unawaited(maybeRequestReview());
  }

  /// End the current session and check if it qualifies
  /// Call this when app goes to background or is closed
  Future<void> endSession() async {
    if (!isEnabled || _sessionStartTime == null) return;

    final sessionDuration = DateTime.now().difference(_sessionStartTime!);
    _sessionStartTime = null;

    if (sessionDuration >= _minimumSessionDuration) {
      await _incrementQualifyingSessions();
      appLogger.d('In-app review: Qualifying session ended (${sessionDuration.inMinutes} minutes)');
    } else {
      appLogger.d('In-app review: Session too short (${sessionDuration.inMinutes} minutes)');
    }
  }

  Future<void> _incrementQualifyingSessions() async {
    final prefs = await _getPrefs();
    final currentCount = prefs.getInt(_keyQualifyingSessionsCount) ?? 0;
    await prefs.setInt(_keyQualifyingSessionsCount, currentCount + 1);
  }

  Future<int> _getQualifyingSessionsCount() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_keyQualifyingSessionsCount) ?? 0;
  }

  /// Check if we should request a review based on session count and cooldown
  Future<bool> _shouldRequestReview() async {
    final prefs = await _getPrefs();

    final sessionCount = await _getQualifyingSessionsCount();
    if (sessionCount < _requiredSessions) {
      appLogger.d('In-app review: Not enough sessions ($sessionCount/$_requiredSessions)');
      return false;
    }

    final lastPromptString = prefs.getString(_keyLastPromptTime);
    if (lastPromptString != null) {
      final lastPrompt = DateTime.parse(lastPromptString);
      final timeSinceLastPrompt = DateTime.now().difference(lastPrompt);
      if (timeSinceLastPrompt < _promptCooldown) {
        final daysRemaining = (_promptCooldown - timeSinceLastPrompt).inDays;
        appLogger.d('In-app review: Cooldown active ($daysRemaining days remaining)');
        return false;
      }
    }

    return true;
  }

  Future<void> maybeRequestReview() async {
    if (!isEnabled) return;

    final shouldRequest = await _shouldRequestReview();
    if (!shouldRequest) return;

    try {
      final isAvailable = await _inAppReview.isAvailable();
      if (!isAvailable) {
        appLogger.d('In-app review: Not available on this device');
        return;
      }

      await _inAppReview.requestReview();
      appLogger.i('In-app review: Review prompt shown');

      await _recordPromptShown();
    } catch (e) {
      appLogger.e('In-app review: Error requesting review', error: e);
    }
  }

  Future<void> _recordPromptShown() async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyLastPromptTime, DateTime.now().toIso8601String());
    // Reset session count so user needs to use app more before next prompt
    await prefs.setInt(_keyQualifyingSessionsCount, 0);
  }
}
