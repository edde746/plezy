import 'package:json_annotation/json_annotation.dart';

part 'remote_session.g.dart';

enum RemoteSessionRole { host, remote }

enum RemoteSessionStatus { disconnected, connecting, connected, reconnecting, error }

@JsonSerializable()
class RemoteDevice {
  final String id;
  final String name;
  final String platform;
  final DateTime connectedAt;
  final Map<String, bool> capabilities;

  RemoteDevice({
    required this.id,
    required this.name,
    required this.platform,
    DateTime? connectedAt,
    Map<String, bool>? capabilities,
  }) : connectedAt = connectedAt ?? DateTime.now(),
       capabilities = capabilities ?? {};

  factory RemoteDevice.fromJson(Map<String, dynamic> json) => _$RemoteDeviceFromJson(json);

  Map<String, dynamic> toJson() => _$RemoteDeviceToJson(this);

  RemoteDevice copyWith({
    String? id,
    String? name,
    String? platform,
    DateTime? connectedAt,
    Map<String, bool>? capabilities,
  }) {
    return RemoteDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      connectedAt: connectedAt ?? this.connectedAt,
      capabilities: capabilities ?? this.capabilities,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RemoteDevice && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@JsonSerializable()
class RemoteSession {
  final String sessionId;
  final String pin;
  @JsonKey(unknownEnumValue: RemoteSessionRole.remote)
  final RemoteSessionRole role;
  @JsonKey(unknownEnumValue: RemoteSessionStatus.disconnected)
  final RemoteSessionStatus status;
  final RemoteDevice? connectedDevice;
  final DateTime createdAt;
  final String? errorMessage;

  RemoteSession({
    required this.sessionId,
    required this.pin,
    required this.role,
    this.status = RemoteSessionStatus.disconnected,
    this.connectedDevice,
    DateTime? createdAt,
    this.errorMessage,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isConnected => status == RemoteSessionStatus.connected;
  bool get isHost => role == RemoteSessionRole.host;
  bool get isRemote => role == RemoteSessionRole.remote;

  factory RemoteSession.fromJson(Map<String, dynamic> json) => _$RemoteSessionFromJson(json);

  Map<String, dynamic> toJson() => _$RemoteSessionToJson(this);

  RemoteSession copyWith({
    String? sessionId,
    String? pin,
    RemoteSessionRole? role,
    RemoteSessionStatus? status,
    RemoteDevice? connectedDevice,
    bool clearConnectedDevice = false,
    DateTime? createdAt,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return RemoteSession(
      sessionId: sessionId ?? this.sessionId,
      pin: pin ?? this.pin,
      role: role ?? this.role,
      status: status ?? this.status,
      connectedDevice: clearConnectedDevice ? null : (connectedDevice ?? this.connectedDevice),
      createdAt: createdAt ?? this.createdAt,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
