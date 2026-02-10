import 'dart:async';
import 'dart:convert';

import '../../models/companion_remote/recent_remote_session.dart';
import '../../services/storage_service.dart';
import '../../utils/app_logger.dart';

/// Service for managing recent Companion Remote sessions
class CompanionRemoteDiscoveryService {
  static const String _storageKey = 'companion_remote_recent_sessions';
  static const int _maxRecentSessions = 5;

  final _recentSessions = <RecentRemoteSession>[];
  final _recentSessionsController = StreamController<List<RecentRemoteSession>>.broadcast();

  /// Stream of recent sessions
  Stream<List<RecentRemoteSession>> get recentSessions => _recentSessionsController.stream;

  /// Get current list of recent sessions
  List<RecentRemoteSession> get currentSessions => List.unmodifiable(_recentSessions);

  CompanionRemoteDiscoveryService() {
    _loadRecentSessions();
  }

  /// Load recent sessions from storage
  Future<void> _loadRecentSessions() async {
    try {
      final storage = await StorageService.getInstance();
      final json = storage.prefs.getString(_storageKey);

      if (json != null) {
        final List<dynamic> list = jsonDecode(json);
        _recentSessions.clear();
        _recentSessions.addAll(list.map((e) => RecentRemoteSession.fromJson(e as Map<String, dynamic>)));

        // Sort by last connected (most recent first)
        _recentSessions.sort((a, b) => b.lastConnected.compareTo(a.lastConnected));

        _recentSessionsController.add(currentSessions);
        appLogger.d('Loaded ${_recentSessions.length} recent remote sessions');
      }
    } catch (e) {
      appLogger.e('Failed to load recent sessions', error: e);
    }
  }

  /// Save recent sessions to storage
  Future<void> _saveRecentSessions() async {
    try {
      final storage = await StorageService.getInstance();
      final json = jsonEncode(_recentSessions.map((e) => e.toJson()).toList());
      await storage.prefs.setString(_storageKey, json);
      appLogger.d('Saved ${_recentSessions.length} recent remote sessions');
    } catch (e) {
      appLogger.e('Failed to save recent sessions', error: e);
    }
  }

  /// Add a session to recent list
  Future<void> addRecentSession(RecentRemoteSession session) async {
    // Remove existing entry for this session ID
    _recentSessions.removeWhere((s) => s.sessionId == session.sessionId);

    // Add new entry at the beginning
    _recentSessions.insert(0, session);

    // Limit to max sessions
    if (_recentSessions.length > _maxRecentSessions) {
      _recentSessions.removeRange(_maxRecentSessions, _recentSessions.length);
    }

    await _saveRecentSessions();
    _recentSessionsController.add(currentSessions);
  }

  /// Remove a session from recent list
  Future<void> removeRecentSession(String sessionId) async {
    _recentSessions.removeWhere((s) => s.sessionId == sessionId);
    await _saveRecentSessions();
    _recentSessionsController.add(currentSessions);
  }

  /// Clear all recent sessions
  Future<void> clearRecentSessions() async {
    _recentSessions.clear();
    await _saveRecentSessions();
    _recentSessionsController.add(currentSessions);
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _recentSessionsController.close();
  }
}
