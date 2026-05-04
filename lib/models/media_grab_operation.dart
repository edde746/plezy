import 'package:json_annotation/json_annotation.dart';

import '../utils/json_utils.dart';
import 'livetv_program.dart';

part 'media_grab_operation.g.dart';

Map<String, dynamic>? _metadataFromJson(Object? raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is List && raw.isNotEmpty && raw.first is Map<String, dynamic>) {
    return raw.first as Map<String, dynamic>;
  }
  return null;
}

LiveTvProgram? _programFromMetadata(Object? raw) {
  final metadata = _metadataFromJson(raw);
  if (metadata == null) return null;
  try {
    return LiveTvProgram.fromJson(metadata);
  } catch (_) {
    return null;
  }
}

/// A scheduled or active Plex DVR grab operation.
@JsonSerializable(createToJson: false)
class MediaGrabOperation {
  @JsonKey(fromJson: flexibleInt)
  final int? mediaSubscriptionID;
  @JsonKey(fromJson: flexibleInt)
  final int? mediaIndex;
  @JsonKey(defaultValue: '')
  final String id;
  final String? key;
  final String? grabberIdentifier;
  final String? grabberProtocol;
  @JsonKey(fromJson: flexibleDouble)
  final double? percent;
  @JsonKey(fromJson: flexibleInt)
  final int? currentSize;
  final String? status;
  final String? provider;
  @JsonKey(fromJson: flexibleBoolNullable)
  final bool? rolling;
  final String? error;
  final String? linkedKey;
  @JsonKey(name: 'Metadata', fromJson: _metadataFromJson)
  final Map<String, dynamic>? metadata;

  const MediaGrabOperation({
    this.mediaSubscriptionID,
    this.mediaIndex,
    required this.id,
    this.key,
    this.grabberIdentifier,
    this.grabberProtocol,
    this.percent,
    this.currentSize,
    this.status,
    this.provider,
    this.rolling,
    this.error,
    this.linkedKey,
    this.metadata,
  });

  factory MediaGrabOperation.fromJson(Map<String, dynamic> json) => _$MediaGrabOperationFromJson(json);

  String get operationKey => (key != null && key!.isNotEmpty) ? key! : id;

  LiveTvProgram? get program => _programFromMetadata(metadata);
}
