/// Data model for video player performance statistics.
///
/// Contains metrics queried from the video player (MPV or ExoPlayer)
/// including video/audio codec info, playback performance, and buffer state.
class PerformanceStats {
  // Player info
  final String playerType; // 'mpv' or 'exoplayer'

  // Video metrics
  final String? videoCodec;
  final int? videoWidth;
  final int? videoHeight;
  final double? videoFps;
  final String? hwdecCurrent;
  final int? videoBitrate;
  final String? aspectName;
  final int? rotate;
  final String? videoDecoderName;

  // Color/Format metrics
  final String? pixelformat;
  final String? hwPixelformat;
  final String? colormatrix;
  final String? primaries;
  final String? gamma;

  // HDR metadata
  final double? maxLuma;
  final double? minLuma;
  final double? maxCll;
  final double? maxFall;

  // Audio metrics
  final String? audioCodec;
  final int? audioSamplerate;
  final String? audioChannels;
  final int? audioBitrate;

  // Performance metrics
  final double? actualFps;
  final double? avsyncChange;
  final double? displayFps;
  final int? frameDropCount;
  final int? decoderFrameDropCount;

  // Buffer metrics
  final int? cacheUsed;
  final double? cacheSpeed;
  final double? cacheDuration;

  // App metrics
  final int? appMemoryBytes;
  final double? uiFps;

  const PerformanceStats({
    this.playerType = 'unknown',
    this.videoCodec,
    this.videoWidth,
    this.videoHeight,
    this.videoFps,
    this.hwdecCurrent,
    this.videoBitrate,
    this.aspectName,
    this.rotate,
    this.videoDecoderName,
    this.pixelformat,
    this.hwPixelformat,
    this.colormatrix,
    this.primaries,
    this.gamma,
    this.maxLuma,
    this.minLuma,
    this.maxCll,
    this.maxFall,
    this.audioCodec,
    this.audioSamplerate,
    this.audioChannels,
    this.audioBitrate,
    this.actualFps,
    this.avsyncChange,
    this.displayFps,
    this.frameDropCount,
    this.decoderFrameDropCount,
    this.cacheUsed,
    this.cacheSpeed,
    this.cacheDuration,
    this.appMemoryBytes,
    this.uiFps,
  });

  /// Creates an empty stats object (used as initial state).
  const PerformanceStats.empty()
    : playerType = 'unknown',
      videoCodec = null,
      videoWidth = null,
      videoHeight = null,
      videoFps = null,
      hwdecCurrent = null,
      videoBitrate = null,
      aspectName = null,
      rotate = null,
      videoDecoderName = null,
      pixelformat = null,
      hwPixelformat = null,
      colormatrix = null,
      primaries = null,
      gamma = null,
      maxLuma = null,
      minLuma = null,
      maxCll = null,
      maxFall = null,
      audioCodec = null,
      audioSamplerate = null,
      audioChannels = null,
      audioBitrate = null,
      actualFps = null,
      avsyncChange = null,
      displayFps = null,
      frameDropCount = null,
      decoderFrameDropCount = null,
      cacheUsed = null,
      cacheSpeed = null,
      cacheDuration = null,
      appMemoryBytes = null,
      uiFps = null;

  /// Format video resolution as "WxH".
  String get resolution {
    if (videoWidth == null || videoHeight == null) return 'N/A';
    return '${videoWidth}x$videoHeight';
  }

  /// Format video bitrate in Mbps.
  String get videoBitrateFormatted {
    if (videoBitrate == null || videoBitrate == 0) return 'N/A';
    final mbps = videoBitrate! / 1000000;
    return '${mbps.toStringAsFixed(1)} Mbps';
  }

  /// Format audio bitrate in kbps.
  String get audioBitrateFormatted {
    if (audioBitrate == null || audioBitrate == 0) return 'N/A';
    final kbps = audioBitrate! / 1000;
    return '${kbps.toStringAsFixed(0)} kbps';
  }

  /// Format audio sample rate in kHz.
  String get sampleRateFormatted {
    if (audioSamplerate == null) return 'N/A';
    final khz = audioSamplerate! / 1000;
    return '${khz.toStringAsFixed(1)} kHz';
  }

  /// Format FPS with 2 decimal places.
  String get actualFpsFormatted {
    if (actualFps == null) return 'N/A';
    return actualFps!.toStringAsFixed(2);
  }

  /// Format source FPS with 2 decimal places.
  String get videoFpsFormatted {
    if (videoFps == null) return 'N/A';
    return videoFps!.toStringAsFixed(2);
  }

  /// Format A/V sync in milliseconds.
  String get avsyncFormatted {
    if (avsyncChange == null) return 'N/A';
    final ms = (avsyncChange! * 1000).round();
    return '${ms > 0 ? '+' : ''}${ms}ms';
  }

  /// Format cache used in MB.
  String get cacheUsedFormatted {
    if (cacheUsed == null) return 'N/A';
    final mb = cacheUsed! / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Format cache speed in MB/s.
  String get cacheSpeedFormatted {
    if (cacheSpeed == null) return 'N/A';
    final mbps = cacheSpeed! / (1024 * 1024);
    return '${mbps.toStringAsFixed(1)} MB/s';
  }

  /// Format cache duration in seconds.
  String get cacheDurationFormatted {
    if (cacheDuration == null) return 'N/A';
    return '${cacheDuration!.toStringAsFixed(1)}s';
  }

  /// Format display FPS.
  String get displayFpsFormatted {
    if (displayFps == null) return 'N/A';
    return displayFps!.toStringAsFixed(0);
  }

  /// Format dropped frames count.
  String get droppedFramesFormatted {
    final total = (frameDropCount ?? 0) + (decoderFrameDropCount ?? 0);
    return total.toString();
  }

  /// Format hardware decoding mode.
  String get hwdecFormatted {
    // For ExoPlayer, use the decoder name
    if (videoDecoderName != null && videoDecoderName!.isNotEmpty) {
      // Check if it's a hardware decoder (contains OMX, c2, or MediaCodec patterns)
      final decoder = videoDecoderName!;
      if (decoder.contains('c2.') || decoder.contains('OMX.') || decoder.contains('.hw.')) {
        // Extract a cleaner name
        if (decoder.contains('c2.android.')) return 'Android HW';
        if (decoder.contains('c2.nvidia')) return 'NVIDIA HW';
        if (decoder.contains('c2.qti') || decoder.contains('c2.qcom')) return 'Qualcomm HW';
        if (decoder.contains('c2.mtk') || decoder.contains('c2.mediatek')) return 'MediaTek HW';
        if (decoder.contains('c2.exynos') || decoder.contains('c2.samsung')) return 'Exynos HW';
        if (decoder.contains('OMX.google')) return 'Software';
        return 'Hardware';
      }
      return 'Software';
    }
    // For MPV, use hwdec-current property
    if (hwdecCurrent == null || hwdecCurrent!.isEmpty || hwdecCurrent == 'no') {
      return 'Software';
    }
    return hwdecCurrent!;
  }

  /// Format app memory usage in MB.
  String get appMemoryFormatted {
    if (appMemoryBytes == null) return 'N/A';
    final mb = appMemoryBytes! / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Format UI FPS with 1 decimal place.
  String get uiFpsFormatted {
    if (uiFps == null) return 'N/A';
    return uiFps!.toStringAsFixed(1);
  }

  /// Format rotation in degrees.
  String get rotateFormatted {
    if (rotate == null || rotate == 0) return 'N/A';
    return '$rotate°';
  }

  /// Format luminance value in cd/m².
  String get maxLumaFormatted {
    if (maxLuma == null) return 'N/A';
    return '${maxLuma!.toStringAsFixed(0)} cd/m²';
  }

  /// Format minimum luminance value in cd/m².
  String get minLumaFormatted {
    if (minLuma == null) return 'N/A';
    return '${minLuma!.toStringAsFixed(4)} cd/m²';
  }

  /// Format MaxCLL value in cd/m².
  String get maxCllFormatted {
    if (maxCll == null) return 'N/A';
    return '${maxCll!.toStringAsFixed(0)} cd/m²';
  }

  /// Format MaxFALL value in cd/m².
  String get maxFallFormatted {
    if (maxFall == null) return 'N/A';
    return '${maxFall!.toStringAsFixed(0)} cd/m²';
  }

  /// Check if HDR metadata is available.
  bool get hasHdrMetadata {
    return maxLuma != null || maxCll != null;
  }

  /// Check if video FPS is valid (not null, not negative, not zero).
  bool get hasValidVideoFps {
    return videoFps != null && videoFps! > 0;
  }

  /// Check if video bitrate is valid (not null, not negative, not zero).
  bool get hasValidVideoBitrate {
    return videoBitrate != null && videoBitrate! > 0;
  }

  /// Check if audio bitrate is valid (not null, not negative, not zero).
  bool get hasValidAudioBitrate {
    return audioBitrate != null && audioBitrate! > 0;
  }

  /// Format player type for display.
  String get playerTypeFormatted {
    return switch (playerType.toLowerCase()) {
      'mpv' => 'MPV',
      'exoplayer' => 'ExoPlayer',
      _ => playerType,
    };
  }
}
