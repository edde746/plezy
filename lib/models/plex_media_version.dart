import 'package:json_annotation/json_annotation.dart';

import '../utils/formatters.dart';
import '../utils/codec_utils.dart';
import '../utils/json_utils.dart';

part 'plex_media_version.g.dart';

int _flexibleIntOrZero(Object? v) => flexibleInt(v) ?? 0;

Object? _readPartKey(Map json, String key) {
  final parts = flexibleList(json['Part']);
  return parts != null && parts.isNotEmpty ? parts.first['key']?.toString() ?? '' : '';
}

@JsonSerializable(createToJson: false)
class PlexMediaVersion {
  @JsonKey(fromJson: _flexibleIntOrZero)
  final int id;
  @JsonKey(readValue: readStringField)
  final String? videoResolution;
  @JsonKey(readValue: readStringField)
  final String? videoCodec;
  @JsonKey(fromJson: flexibleInt)
  final int? bitrate;
  @JsonKey(fromJson: flexibleInt)
  final int? width;
  @JsonKey(fromJson: flexibleInt)
  final int? height;
  @JsonKey(readValue: readStringField)
  final String? container;
  @JsonKey(readValue: _readPartKey)
  final String partKey;

  PlexMediaVersion({
    required this.id,
    this.videoResolution,
    this.videoCodec,
    this.bitrate,
    this.width,
    this.height,
    this.container,
    required this.partKey,
  });

  /// Creates a PlexMediaVersion from Plex API Media object.
  /// Values may be String or int depending on the response format (XML vs JSON).
  factory PlexMediaVersion.fromJson(Map<String, dynamic> json) => _$PlexMediaVersionFromJson(json);

  /// Display label with detailed information: "1080p H.264 MKV (8.5 Mbps)"
  String get displayLabel {
    final parts = <String>[];

    // Add resolution
    if (videoResolution != null && videoResolution!.isNotEmpty) {
      parts.add('${videoResolution}p');
    } else if (height != null) {
      parts.add('${height}p');
    }

    // Add codec
    if (videoCodec != null && videoCodec!.isNotEmpty) {
      parts.add(CodecUtils.formatVideoCodec(videoCodec!));
    }

    // Add container
    if (container != null && container!.isNotEmpty) {
      parts.add(container!.toUpperCase());
    }

    // Build main label
    String label = parts.isNotEmpty ? parts.join(' ') : 'Unknown';

    // Add bitrate in parentheses
    if (bitrate != null && bitrate! > 0) {
      label += ' (${ByteFormatter.formatBitrate(bitrate!)})';
    }

    return label;
  }

  /// Version signature for matching across episodes.
  /// Format: "resolution:codec:container" (e.g., "1080:h264:mkv")
  String get signature {
    final res = videoResolution ?? '';
    final codec = videoCodec ?? '';
    final cont = container ?? '';
    return '$res:$codec:$cont'.toLowerCase();
  }

  String get _resolutionPart => (videoResolution ?? '').toLowerCase();
  String get _codecPart => (videoCodec ?? '').toLowerCase();

  /// Find the best matching version index from a set of accepted signatures.
  /// Uses tiered matching: exact → resolution+codec → resolution only.
  /// Returns null if no accepted signature matches at all.
  static int? findMatchingIndex(List<PlexMediaVersion> versions, Set<String> acceptedSignatures) {
    if (versions.isEmpty || acceptedSignatures.isEmpty) return null;

    for (final sig in acceptedSignatures) {
      final parts = sig.split(':');
      if (parts.length != 3) continue;
      final targetRes = parts[0];
      final targetCodec = parts[1];

      // Tier 1: exact match
      for (int i = 0; i < versions.length; i++) {
        if (versions[i].signature == sig) return i;
      }

      // Tier 2: resolution + codec
      for (int i = 0; i < versions.length; i++) {
        if (versions[i]._resolutionPart == targetRes && versions[i]._codecPart == targetCodec) return i;
      }

      // Tier 3: resolution only
      for (int i = 0; i < versions.length; i++) {
        if (versions[i]._resolutionPart == targetRes) return i;
      }
    }

    return null;
  }

  @override
  String toString() => displayLabel;
}
