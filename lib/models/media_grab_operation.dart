import 'package:json_annotation/json_annotation.dart';

import '../utils/json_utils.dart';
import 'livetv_program.dart';

part 'media_grab_operation.g.dart';

Map<String, dynamic>? _metadataFromJson(Object? raw) => firstFlexibleMap(raw);

/// The nested airing key varies with grab status in PMS JSON: `scheduled`
/// grabs nest it under `Metadata`, while active/`complete`/`error` grabs (and
/// every grab in XML-derived payloads) use `Video` (issue #2009 captures).
Object? _readGrabMetadata(Map json, String key) => json['Metadata'] ?? json['Video'];

LiveTvProgram? _programFromMetadata(Object? raw) => parseFlexibleJsonObject(raw, LiveTvProgram.fromJson);

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
  @JsonKey(name: 'Metadata', readValue: _readGrabMetadata, fromJson: _metadataFromJson)
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
