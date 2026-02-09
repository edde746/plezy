import 'dart:async';
import 'dart:convert';

import '../../services/storage_service.dart';
import '../../utils/app_logger.dart';

/// Recent Companion Remote session for quick reconnection
class RecentRemoteSession {
  final String sessionId;
  final String pin;
  final String deviceName;
  final String platform;
  final DateTime lastConnected;

  RecentRemoteSession({
    required this.sessionId,
    required this.pin,
    required this.deviceName,
    required this.platform,
    required this.lastConnected,
  });

  factory RecentRemoteSession.fromJson(Map<String, dynamic> json) {
    return RecentRemoteSession(
      sessionId: json['sessionId'] as String,
      pin: json['pin'] as String,
      deviceName: json['deviceName'] as String,
      platform: json['platform'] as String,
      lastConnected: DateTime.parse(json['lastConnected'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'pin': pin,
      'deviceName': deviceName,
      'platform': platform,
      'lastConnected': lastConnected.toIso8601String(),
    };
  }

  /// Create from QR code data (format: "sessionId:pin:deviceName:platform")
  factory RecentRemoteSession.fromQrData(String qrData) {
    final parts = qrData.split(':');
    if (parts.length < 2) {
      throw FormatException('Invalid QR code format');
    }

    return RecentRemoteSession(
      sessionId: parts[0],
      pin: parts[1],
      deviceName: parts.length > 2 ? parts[2] : 'Unknown Device',
      platform: parts.length > 3 ? parts[3] : 'unknown',
      lastConnected: DateTime.now(),
    );
  }

  @override
  String toString() => '$deviceName ($platform) - Last: ${lastConnected.toLocal()}';
}

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
        _recentSessions.addAll(
          list.map((e) => RecentRemoteSession.fromJson(e as Map<String, dynamic>)),
        );

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
