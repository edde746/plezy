import 'package:json_annotation/json_annotation.dart';

part 'trusted_device.g.dart';

@JsonSerializable()
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
  }) : firstConnected = firstConnected ?? DateTime.now(),
       lastConnected = lastConnected ?? DateTime.now();

  factory TrustedDevice.fromJson(Map<String, dynamic> json) => _$TrustedDeviceFromJson(json);

  Map<String, dynamic> toJson() => _$TrustedDeviceToJson(this);

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
