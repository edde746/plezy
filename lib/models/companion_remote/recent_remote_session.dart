import 'package:json_annotation/json_annotation.dart';

part 'recent_remote_session.g.dart';

/// Recent Companion Remote session for quick reconnection
@JsonSerializable()
class RecentRemoteSession {
  final String sessionId;
  final String pin;
  final String deviceName;
  final String platform;
  final DateTime lastConnected;
  final String? hostAddress; // Format: "ip:port"

  RecentRemoteSession({
    required this.sessionId,
    required this.pin,
    required this.deviceName,
    required this.platform,
    required this.lastConnected,
    this.hostAddress,
  });

  factory RecentRemoteSession.fromJson(Map<String, dynamic> json) => _$RecentRemoteSessionFromJson(json);

  Map<String, dynamic> toJson() => _$RecentRemoteSessionToJson(this);

  /// Create from QR code data (format: "ip|port|sessionId|pin")
  factory RecentRemoteSession.fromQrData(String qrData) {
    final parts = qrData.split('|');
    if (parts.length < 4) {
      throw FormatException('Invalid QR code format - expected ip|port|sessionId|pin');
    }

    final ip = parts[0];
    final port = parts[1];
    final sessionId = parts[2];
    final pin = parts[3];

    return RecentRemoteSession(
      sessionId: sessionId,
      pin: pin,
      deviceName: 'Unknown Device',
      platform: 'unknown',
      lastConnected: DateTime.now(),
      hostAddress: '$ip:$port',
    );
  }

  @override
  String toString() => '$deviceName ($platform) - Last: ${lastConnected.toLocal()}';
}
