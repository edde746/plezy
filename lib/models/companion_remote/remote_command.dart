import 'package:json_annotation/json_annotation.dart';

import 'remote_command_type.dart';

part 'remote_command.g.dart';

@JsonSerializable()
class RemoteCommand {
  @JsonKey(unknownEnumValue: RemoteCommandType.ping)
  final RemoteCommandType type;
  final String deviceId;
  final String deviceName;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  RemoteCommand({required this.type, required this.deviceId, required this.deviceName, DateTime? timestamp, this.data})
    : timestamp = timestamp ?? DateTime.now();

  factory RemoteCommand.fromJson(Map<String, dynamic> json) => _$RemoteCommandFromJson(json);

  Map<String, dynamic> toJson() => _$RemoteCommandToJson(this);

  RemoteCommand copyWith({
    RemoteCommandType? type,
    String? deviceId,
    String? deviceName,
    DateTime? timestamp,
    Map<String, dynamic>? data,
  }) {
    return RemoteCommand(
      type: type ?? this.type,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      timestamp: timestamp ?? this.timestamp,
      data: data ?? this.data,
    );
  }

  @override
  String toString() {
    return 'RemoteCommand(type: ${type.name}, device: $deviceName, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RemoteCommand &&
        other.type == type &&
        other.deviceId == deviceId &&
        other.deviceName == deviceName &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return type.hashCode ^ deviceId.hashCode ^ deviceName.hashCode ^ timestamp.hashCode;
  }
}
