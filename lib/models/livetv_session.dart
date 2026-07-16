import 'package:json_annotation/json_annotation.dart';

import '../utils/json_utils.dart';
import 'livetv_capture_buffer.dart';
import 'livetv_program.dart';
import 'media_grab_operation.dart';

part 'livetv_session.g.dart';

LiveTvProgram? _programFromRaw(Object? raw) => parseFlexibleJsonObject(raw, LiveTvProgram.fromJson);

MediaGrabOperation? _grabOperationFromRaw(Object? raw) => parseFlexibleJsonObject(raw, MediaGrabOperation.fromJson);

CaptureBuffer? _captureBufferFromRaw(Object? raw) {
  final map = firstFlexibleMap(raw);
  if (map == null) return null;
  final session = firstFlexibleMap(map['TranscodeSession']) ?? map;
  return CaptureBuffer.fromTranscodeSession(session);
}

@JsonSerializable(createToJson: false)
class LiveTvSession {
  @JsonKey(readValue: readStringField, defaultValue: '')
  final String sessionID;
  @JsonKey(readValue: readStringField)
  final String? dvrID;
  final String? channelIdentifier;
  final String? channelCallSign;
  final String? channelTitle;
  final String? activityUUID;
  @JsonKey(fromJson: flexibleInt)
  final int? currentPosition;
  @JsonKey(fromJson: flexibleInt)
  final int? nextPosition;
  @JsonKey(fromJson: flexibleInt)
  final int? startedAt;
  @JsonKey(name: 'CaptureBuffer', fromJson: _captureBufferFromRaw)
  final CaptureBuffer? captureBuffer;
  @JsonKey(name: 'MediaGrabOperation', fromJson: _grabOperationFromRaw)
  final MediaGrabOperation? grabOperation;
  @JsonKey(name: 'Timeline', fromJson: firstFlexibleMap)
  final Map<String, dynamic>? timeline;
  @JsonKey(name: 'AiringMetadataItem', fromJson: _programFromRaw)
  final LiveTvProgram? airingMetadataItem;
  @JsonKey(name: 'UpNextMetadataItem', fromJson: _programFromRaw)
  final LiveTvProgram? upNextMetadataItem;

  const LiveTvSession({
    required this.sessionID,
    this.dvrID,
    this.channelIdentifier,
    this.channelCallSign,
    this.channelTitle,
    this.activityUUID,
    this.currentPosition,
    this.nextPosition,
    this.startedAt,
    this.captureBuffer,
    this.grabOperation,
    this.timeline,
    this.airingMetadataItem,
    this.upNextMetadataItem,
  });

  factory LiveTvSession.fromJson(Map<String, dynamic> json) => _$LiveTvSessionFromJson(json);
}
