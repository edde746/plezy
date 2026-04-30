import '../utils/formatters.dart';
import 'media_source_info.dart';

/// Backend-neutral file-info payload rendered by [FileInfoBottomSheet].
///
/// Both Plex and Jellyfin can populate any subset of these fields; rows that
/// don't apply to the active backend are left null and skipped at render
/// time. Plex fills the full set from `/library/metadata/{id}` (Media + Part
/// + Stream); Jellyfin fills the subset that's available on inline
/// `MediaSources`.
class MediaFileInfo {
  // Media level properties
  final String? container;
  final String? videoCodec;
  final String? videoResolution;
  final String? videoFrameRate;
  final String? videoProfile;
  final int? width;
  final int? height;
  final double? aspectRatio;
  final int? bitrate;
  final int? duration;
  final String? audioCodec;
  final String? audioProfile;
  final int? audioChannels;
  final bool? optimizedForStreaming;
  final bool? has64bitOffsets;

  // Part level properties (file)
  final String? filePath;
  final int? fileSize;

  // Stream level properties (video stream details)
  final String? colorSpace;
  final String? colorRange;
  final String? colorPrimaries;
  final String? chromaSubsampling;
  final double? frameRate;
  final int? bitDepth;
  final int? videoBitrate;
  final String? audioChannelLayout;

  // Multi-track support
  final List<MediaAudioTrack> audioTracks;
  final List<MediaSubtitleTrack> subtitleTracks;

  MediaFileInfo({
    this.container,
    this.videoCodec,
    this.videoResolution,
    this.videoFrameRate,
    this.videoProfile,
    this.width,
    this.height,
    this.aspectRatio,
    this.bitrate,
    this.duration,
    this.audioCodec,
    this.audioProfile,
    this.audioChannels,
    this.optimizedForStreaming,
    this.has64bitOffsets,
    this.filePath,
    this.fileSize,
    this.colorSpace,
    this.colorRange,
    this.colorPrimaries,
    this.chromaSubsampling,
    this.frameRate,
    this.bitDepth,
    this.videoBitrate,
    this.audioChannelLayout,
    this.audioTracks = const [],
    this.subtitleTracks = const [],
  });

  String? get fileSizeFormatted {
    if (fileSize == null) return null;
    return ByteFormatter.formatBytes(fileSize!, decimals: 2);
  }

  String? get durationFormatted {
    if (duration == null) return null;
    final seconds = duration! ~/ 1000;
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return hours > 0 ? '${hours}h ${minutes}m ${secs}s' : '${minutes}m ${secs}s';
  }

  String? get bitrateFormatted {
    if (bitrate == null) return null;
    return ByteFormatter.formatBitrate(bitrate!);
  }

  String? get videoBitrateFormatted {
    if (videoBitrate == null) return null;
    return ByteFormatter.formatBitrate(videoBitrate!);
  }

  String? get resolutionFormatted {
    if (width != null && height != null) return '${width}x$height';
    if (videoResolution != null) return videoResolution;
    return null;
  }

  String? get aspectRatioFormatted => aspectRatio?.toStringAsFixed(2);

  String? get frameRateFormatted {
    if (frameRate != null) return '${frameRate!.toStringAsFixed(3)} fps';
    if (videoFrameRate != null) return videoFrameRate;
    return null;
  }

  String? get audioChannelsFormatted {
    if (audioChannels == null) return null;
    var channelText = '$audioChannels channel${audioChannels! > 1 ? 's' : ''}';
    if (audioChannelLayout != null) channelText += ' ($audioChannelLayout)';
    return channelText;
  }
}
