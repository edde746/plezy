class PlexFileInfo {
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
  final String? colorTrc;
  final String? chromaSubsampling;
  final double? frameRate;
  final int? bitDepth;
  final String? audioChannelLayout;

  PlexFileInfo({
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
    this.colorTrc,
    this.chromaSubsampling,
    this.frameRate,
    this.bitDepth,
    this.audioChannelLayout,
  });

  /// Format file size in human-readable format (GB, MB, KB, bytes)
  String get fileSizeFormatted {
    if (fileSize == null) return 'Unknown';

    const kb = 1024;
    const mb = kb * 1024;
    const gb = mb * 1024;

    if (fileSize! >= gb) {
      return '${(fileSize! / gb).toStringAsFixed(2)} GB';
    } else if (fileSize! >= mb) {
      return '${(fileSize! / mb).toStringAsFixed(2)} MB';
    } else if (fileSize! >= kb) {
      return '${(fileSize! / kb).toStringAsFixed(2)} KB';
    } else {
      return '$fileSize bytes';
    }
  }

  /// Format duration in HH:MM:SS or MM:SS format
  String get durationFormatted {
    if (duration == null) return 'Unknown';

    final seconds = duration! ~/ 1000;
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else {
      return '${minutes}m ${secs}s';
    }
  }

  /// Format bitrate in Mbps or Kbps
  String get bitrateFormatted {
    if (bitrate == null) return 'Unknown';

    const kbps = 1000;
    const mbps = kbps * 1000;

    if (bitrate! >= mbps) {
      return '${(bitrate! / mbps).toStringAsFixed(2)} Mbps';
    } else if (bitrate! >= kbps) {
      return '${(bitrate! / kbps).toStringAsFixed(2)} Kbps';
    } else {
      return '$bitrate bps';
    }
  }

  /// Format resolution as widthxheight
  String get resolutionFormatted {
    if (width != null && height != null) {
      return '${width}x$height';
    } else if (videoResolution != null) {
      return videoResolution!;
    }
    return 'Unknown';
  }

  /// Format aspect ratio
  String get aspectRatioFormatted {
    if (aspectRatio != null) {
      return aspectRatio!.toStringAsFixed(2);
    }
    return 'Unknown';
  }

  /// Format frame rate
  String get frameRateFormatted {
    if (frameRate != null) {
      return '${frameRate!.toStringAsFixed(3)} fps';
    } else if (videoFrameRate != null) {
      return videoFrameRate!;
    }
    return 'Unknown';
  }

  /// Format audio channels (e.g., "2 channels (stereo)")
  String get audioChannelsFormatted {
    if (audioChannels != null) {
      String channelText =
          '$audioChannels channel${audioChannels! > 1 ? 's' : ''}';
      if (audioChannelLayout != null) {
        channelText += ' ($audioChannelLayout)';
      }
      return channelText;
    }
    return 'Unknown';
  }
}
