import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/platform_helper.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

/// Service to manage in-app review prompts
/// Only enabled when ENABLE_IN_APP_REVIEW build flag is set
class InAppReviewService {
  static final InAppReviewService _instance = InAppReviewService._();
  static InAppReviewService get instance => _instance;

  InAppReviewService._();

  final InAppReview _inAppReview = InAppReview.instance;

  // SharedPreferences keys
  static const String _keyQualifyingSessionsCount = 'review_qualifying_sessions_count';
  static const String _keyLastPromptTime = 'review_last_prompt_time';

  // Configuration
  static const int _requiredSessions = 6;
  static const Duration _minimumSessionDuration = Duration(minutes: 5);
  static const Duration _promptCooldown = Duration(days: 60);

  // Session tracking
  DateTime? _sessionStartTime;

  /// Check if in-app review is enabled via build flag
  /// Only enabled on mobile platforms (iOS and Android)
  static bool get isEnabled {
    if (kIsWeb || (!AppPlatform.isIOS && !AppPlatform.isAndroid)) {
      return false;
    }
    const enabled = bool.fromEnvironment('ENABLE_IN_APP_REVIEW', defaultValue: false);
    return enabled;
  }

  /// Start tracking a new session
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

  /// Increment the qualifying sessions counter
  Future<void> _incrementQualifyingSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_keyQualifyingSessionsCount) ?? 0;
    await prefs.setInt(_keyQualifyingSessionsCount, currentCount + 1);
  }

  /// Get the current qualifying sessions count
  Future<int> _getQualifyingSessionsCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyQualifyingSessionsCount) ?? 0;
  }

  /// Check if we should request a review based on session count and cooldown
  Future<bool> _shouldRequestReview() async {
    final prefs = await SharedPreferences.getInstance();

    // Check session count
    final sessionCount = await _getQualifyingSessionsCount();
    if (sessionCount < _requiredSessions) {
      appLogger.d('In-app review: Not enough sessions ($sessionCount/$_requiredSessions)');
      return false;
    }

    // Check cooldown
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

  /// Request a review if conditions are met
  Future<void> maybeRequestReview() async {
    if (!isEnabled) return;

    final shouldRequest = await _shouldRequestReview();
    if (!shouldRequest) return;

    try {
      // Check if in-app review is available on this device
      final isAvailable = await _inAppReview.isAvailable();
      if (!isAvailable) {
        appLogger.d('In-app review: Not available on this device');
        return;
      }

      // Request the review
      await _inAppReview.requestReview();
      appLogger.i('In-app review: Review prompt shown');

      // Record that we showed the prompt and reset session count
      await _recordPromptShown();
    } catch (e) {
      appLogger.e('In-app review: Error requesting review', error: e);
    }
  }

  /// Record that the review prompt was shown
  Future<void> _recordPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastPromptTime, DateTime.now().toIso8601String());
    // Reset session count so user needs to use app more before next prompt
    await prefs.setInt(_keyQualifyingSessionsCount, 0);
  }

  /// Get debug info about the current state (for development/testing)
  Future<Map<String, dynamic>> getDebugInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionCount = prefs.getInt(_keyQualifyingSessionsCount) ?? 0;
    final lastPromptString = prefs.getString(_keyLastPromptTime);
    final isAvailable = await _inAppReview.isAvailable();

    return {
      'isEnabled': isEnabled,
      'isAvailable': isAvailable,
      'qualifyingSessions': sessionCount,
      'requiredSessions': _requiredSessions,
      'lastPromptTime': lastPromptString,
      'cooldownDays': _promptCooldown.inDays,
      'currentSessionStartTime': _sessionStartTime?.toIso8601String(),
    };
  }

  /// Reset all stored data (for testing purposes)
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyQualifyingSessionsCount);
    await prefs.remove(_keyLastPromptTime);
    _sessionStartTime = null;
    appLogger.d('In-app review: State reset');
  }
}
