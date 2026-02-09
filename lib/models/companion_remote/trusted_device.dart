class TrustedDevice {
  final String peerId;
  final String deviceName;
  final String platform;
  final DateTime firstConnected;
  final DateTime lastConnected;
  final bool isApproved;

  TrustedDevice({
    required this.peerId,
    required this.deviceName,
    required this.platform,
    DateTime? firstConnected,
    DateTime? lastConnected,
    this.isApproved = false,
  })  : firstConnected = firstConnected ?? DateTime.now(),
        lastConnected = lastConnected ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'peerId': peerId,
      'deviceName': deviceName,
      'platform': platform,
      'firstConnected': firstConnected.toIso8601String(),
      'lastConnected': lastConnected.toIso8601String(),
      'isApproved': isApproved,
    };
  }

  factory TrustedDevice.fromJson(Map<String, dynamic> json) {
    return TrustedDevice(
      peerId: json['peerId'] as String,
      deviceName: json['deviceName'] as String,
      platform: json['platform'] as String,
      firstConnected: DateTime.parse(json['firstConnected'] as String),
      lastConnected: DateTime.parse(json['lastConnected'] as String),
      isApproved: json['isApproved'] as bool? ?? false,
    );
  }

  TrustedDevice copyWith({
    String? peerId,
    String? deviceName,
    String? platform,
    DateTime? firstConnected,
    DateTime? lastConnected,
    bool? isApproved,
  }) {
    return TrustedDevice(
      peerId: peerId ?? this.peerId,
      deviceName: deviceName ?? this.deviceName,
      platform: platform ?? this.platform,
      firstConnected: firstConnected ?? this.firstConnected,
      lastConnected: lastConnected ?? this.lastConnected,
      isApproved: isApproved ?? this.isApproved,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrustedDevice && other.peerId == peerId;
  }

  @override
  int get hashCode => peerId.hashCode;
}
