import '../utils/formatters.dart';
import '../utils/codec_utils.dart';

class PlexMediaVersion {
  final int id;
  final String? videoResolution;
  final String? videoCodec;
  final int? bitrate;
  final int? width;
  final int? height;
  final String? container;
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

  /// Creates a PlexMediaVersion from Plex API Media object
  factory PlexMediaVersion.fromJson(Map<String, dynamic> json) {
    // Get the first Part key for playback
    final parts = json['Part'] as List<dynamic>?;
    final partKey = parts != null && parts.isNotEmpty ? parts[0]['key'] as String? ?? '' : '';

    return PlexMediaVersion(
      id: json['id'] as int? ?? 0,
      videoResolution: json['videoResolution'] as String?,
      videoCodec: json['videoCodec'] as String?,
      bitrate: json['bitrate'] as int?,
      width: json['width'] as int?,
      height: json['height'] as int?,
      container: json['container'] as String?,
      partKey: partKey,
    );
  }

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

  @override
  String toString() => displayLabel;
}
