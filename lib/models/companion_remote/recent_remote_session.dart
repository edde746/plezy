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

  RecentRemoteSession({
    required this.sessionId,
    required this.pin,
    required this.deviceName,
    required this.platform,
    required this.lastConnected,
  });

  factory RecentRemoteSession.fromJson(Map<String, dynamic> json) => _$RecentRemoteSessionFromJson(json);

  Map<String, dynamic> toJson() => _$RecentRemoteSessionToJson(this);

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
