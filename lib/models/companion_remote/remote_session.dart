enum RemoteSessionRole {
  host,
  remote,
}

enum RemoteSessionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

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
  })  : connectedAt = connectedAt ?? DateTime.now(),
        capabilities = capabilities ?? {};

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'platform': platform,
      'connectedAt': connectedAt.toIso8601String(),
      'capabilities': capabilities,
    };
  }

  factory RemoteDevice.fromJson(Map<String, dynamic> json) {
    return RemoteDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      platform: json['platform'] as String,
      connectedAt: DateTime.parse(json['connectedAt'] as String),
      capabilities: Map<String, bool>.from(json['capabilities'] as Map? ?? {}),
    );
  }

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

class RemoteSession {
  final String sessionId;
  final String pin;
  final RemoteSessionRole role;
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

  RemoteSession copyWith({
    String? sessionId,
    String? pin,
    RemoteSessionRole? role,
    RemoteSessionStatus? status,
    RemoteDevice? connectedDevice,
    DateTime? createdAt,
    String? errorMessage,
  }) {
    return RemoteSession(
      sessionId: sessionId ?? this.sessionId,
      pin: pin ?? this.pin,
      role: role ?? this.role,
      status: status ?? this.status,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      createdAt: createdAt ?? this.createdAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'pin': pin,
      'role': role.name,
      'status': status.name,
      'connectedDevice': connectedDevice?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }

  factory RemoteSession.fromJson(Map<String, dynamic> json) {
    return RemoteSession(
      sessionId: json['sessionId'] as String,
      pin: json['pin'] as String,
      role: RemoteSessionRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => RemoteSessionRole.remote,
      ),
      status: RemoteSessionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RemoteSessionStatus.disconnected,
      ),
      connectedDevice: json['connectedDevice'] != null
          ? RemoteDevice.fromJson(json['connectedDevice'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      errorMessage: json['errorMessage'] as String?,
    );
  }
}
