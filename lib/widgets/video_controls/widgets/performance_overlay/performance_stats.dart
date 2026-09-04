import '../../../../i18n/strings.g.dart';
import '../../../../utils/codec_utils.dart';

/// Data model for video player performance statistics.
///
/// Contains metrics queried from the video player (MPV or ExoPlayer)
/// including video/audio codec info, playback performance, and buffer state.
class PerformanceStats {
  final String playerType;

  final String? videoCodec;
  final int? videoWidth;
  final int? videoHeight;
  final double? videoFps;
  final String? hwdecCurrent;
  final int? videoBitrate;
  final String? aspectName;
  final int? rotate;
  final String? videoDecoderName;

  final String? pixelformat;
  final String? hwPixelformat;
  final String? colormatrix;
  final String? primaries;
  final String? gamma;

  final double? maxLuma;
  final double? minLuma;
  final double? maxCll;
  final double? maxFall;

  final String? audioCodec;
  final int? audioSamplerate;
  final String? audioChannels;
  final int? audioBitrate;
  final String? audioDecoderName;

  /// mpv `audio-params/format` when it names an IEC 61937 bitstream
  /// ('spdif-eac3'); null when audio is decoded locally.
  final String? audioPassthroughFormat;

  final bool tunneledPlayback;
  final String? tunnelingStatus;

  final double? actualFps;
  final double? avsyncChange;
  final double? displayFps;
  final int? frameDropCount;
  final int? decoderFrameDropCount;

  final int? cacheUsed;
  final int? cacheLimit;
  final double? cacheSpeed;
  final double? cacheDuration;
  final int? bufferTargetBytes;
  final int? bufferMaxMs;

  final bool dvConversionActive;
  final String dvConversionMode;
  final int? dvConvertedRpus;
  final int? dvRpuConversionFailures;
  final int? dvAvgRpuConversionUs;
  final int? dvAvgSampleProcessingUs;
  final int? dvSourceProfile;
  final String? dvPlaybackPath;

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
    this.audioDecoderName,
    this.audioPassthroughFormat,
    this.tunneledPlayback = false,
    this.tunnelingStatus,
    this.actualFps,
    this.avsyncChange,
    this.displayFps,
    this.frameDropCount,
    this.decoderFrameDropCount,
    this.cacheUsed,
    this.cacheLimit,
    this.cacheSpeed,
    this.cacheDuration,
    this.bufferTargetBytes,
    this.bufferMaxMs,
    this.dvConversionActive = false,
    this.dvConversionMode = '',
    this.dvConvertedRpus,
    this.dvRpuConversionFailures,
    this.dvAvgRpuConversionUs,
    this.dvAvgSampleProcessingUs,
    this.dvSourceProfile,
    this.dvPlaybackPath,
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
      audioDecoderName = null,
      audioPassthroughFormat = null,
      tunneledPlayback = false,
      tunnelingStatus = null,
      actualFps = null,
      avsyncChange = null,
      displayFps = null,
      frameDropCount = null,
      decoderFrameDropCount = null,
      cacheUsed = null,
      cacheLimit = null,
      cacheSpeed = null,
      cacheDuration = null,
      bufferTargetBytes = null,
      bufferMaxMs = null,
      dvConversionActive = false,
      dvConversionMode = '',
      dvConvertedRpus = null,
      dvRpuConversionFailures = null,
      dvAvgRpuConversionUs = null,
      dvAvgSampleProcessingUs = null,
      dvSourceProfile = null,
      dvPlaybackPath = null,
      appMemoryBytes = null,
      uiFps = null;

  /// Format video resolution as "WxH".
  String get resolution {
    if (videoWidth == null || videoHeight == null) return t.common.notAvailable;
    return '${videoWidth}x$videoHeight';
  }

  /// Format video bitrate in Mbps.
  String get videoBitrateFormatted {
    if (videoBitrate == null || videoBitrate == 0) return t.common.notAvailable;
    final mbps = videoBitrate! / 1_000_000;
    return '${mbps.toStringAsFixed(1)} Mbps';
  }

  /// Both ExoPlayer read-ahead ceilings: the duration target and the hard byte cap.
  /// The smaller one binds, so showing both explains a duration setting that
  /// appears to have no effect on high-bitrate media.
  String get bufferLimitsFormatted {
    if (bufferMaxMs == null || bufferMaxMs! <= 0) return t.common.notAvailable;
    final duration = '${bufferMaxMs! ~/ 1000}s';
    if (bufferTargetBytes == null) return duration;
    final targetBufferMb = bufferTargetBytes! ~/ (1024 * 1024);
    return '$duration / ${targetBufferMb}MB';
  }

  /// Format audio bitrate in kbps.
  String get audioBitrateFormatted {
    if (audioBitrate == null || audioBitrate == 0) return t.common.notAvailable;
    final kbps = audioBitrate! / 1000;
    return '${kbps.toStringAsFixed(0)} kbps';
  }

  /// Format audio sample rate in kHz.
  String get sampleRateFormatted {
    if (audioSamplerate == null) return t.common.notAvailable;
    final khz = audioSamplerate! / 1000;
    return '${khz.toStringAsFixed(1)} kHz';
  }

  /// Whether audio is bitstreamed to the device instead of decoded locally.
  bool get audioPassthrough => audioPassthroughFormat != null;

  /// Format the bitstreamed codec ('spdif-eac3' → 'E-AC3').
  String get audioPassthroughFormatted {
    final format = audioPassthroughFormat;
    if (format == null) return t.common.notAvailable;
    final codec = format.startsWith('spdif-') ? format.substring('spdif-'.length) : format;
    return CodecUtils.formatAudioCodec(codec);
  }

  /// Format FPS with 2 decimal places.
  String get actualFpsFormatted {
    if (actualFps == null) return t.common.notAvailable;
    return actualFps!.toStringAsFixed(2);
  }

  /// Format source FPS with 2 decimal places.
  String get videoFpsFormatted {
    if (videoFps == null) return t.common.notAvailable;
    return videoFps!.toStringAsFixed(2);
  }

  /// Format A/V sync in milliseconds.
  String get avsyncFormatted {
    if (avsyncChange == null) return t.common.notAvailable;
    final ms = (avsyncChange! * 1000).round();
    return '${ms > 0 ? '+' : ''}${ms}ms';
  }

  /// Format cache used in MB.
  String get cacheUsedFormatted {
    if (cacheUsed == null) return t.common.notAvailable;
    final mb = cacheUsed! / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Format cache limit in MB.
  String get cacheLimitFormatted {
    if (cacheLimit == null || cacheLimit! <= 0) return t.common.notAvailable;
    final mb = cacheLimit! / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Format cache speed in MB/s.
  String get cacheSpeedFormatted {
    if (cacheSpeed == null) return t.common.notAvailable;
    final mbps = cacheSpeed! / (1024 * 1024);
    return '${mbps.toStringAsFixed(1)} MB/s';
  }

  /// Format cache duration in seconds.
  String get cacheDurationFormatted {
    if (cacheDuration == null) return t.common.notAvailable;
    return '${cacheDuration!.toStringAsFixed(1)}s';
  }

  /// Format display FPS.
  String get displayFpsFormatted {
    if (displayFps == null) return t.common.notAvailable;
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
        if (decoder.contains('c2.android.')) return t.performanceOverlay.decoderAndroidHw;
        if (decoder.contains('c2.nvidia')) return t.performanceOverlay.decoderNvidiaHw;
        if (decoder.contains('c2.qti') || decoder.contains('c2.qcom')) {
          return t.performanceOverlay.decoderQualcommHw;
        }
        if (decoder.contains('c2.mtk') || decoder.contains('c2.mediatek')) {
          return t.performanceOverlay.decoderMediatekHw;
        }
        if (decoder.contains('c2.exynos') || decoder.contains('c2.samsung')) {
          return t.performanceOverlay.decoderExynosHw;
        }
        if (decoder.contains('OMX.google')) return t.performanceOverlay.decoderSoftware;
        return t.performanceOverlay.decoderHardware;
      }
      return t.performanceOverlay.decoderSoftware;
    }
    // For MPV, use hwdec-current property
    if (hwdecCurrent == null || hwdecCurrent!.isEmpty || hwdecCurrent == 'no') {
      return t.performanceOverlay.decoderSoftware;
    }
    return hwdecCurrent!;
  }

  /// Raw video decoder name (e.g. c2.qti.video.decoder.hevc).
  String get videoDecoderRaw => videoDecoderName ?? t.common.notAvailable;

  /// Format audio decoder name for display.
  String get audioDecoderFormatted => audioDecoderName ?? t.common.notAvailable;

  /// Format tunneled playback status with reason.
  String get tunneledPlaybackFormatted =>
      tunnelingStatus ?? (tunneledPlayback ? t.performanceOverlay.tunnelingActive : t.common.off);

  /// Format DV conversion mode for display.
  String get dvConversionFormatted => dvConversionMode == 'DV81' ? '7→8.1' : '7→HEVC';

  /// Format Dolby Vision source profile.
  String get dvSourceProfileFormatted => dvSourceProfile == null ? t.common.notAvailable : 'P$dvSourceProfile';

  /// Format Dolby Vision playback path.
  String get dvPlaybackPathFormatted => dvPlaybackPath ?? t.common.notAvailable;

  /// Format DV RPU conversion totals.
  String get dvRpuCountFormatted {
    final converted = dvConvertedRpus ?? 0;
    final failures = dvRpuConversionFailures ?? 0;
    return failures > 0
        ? t.performanceOverlay.dvRpuFailed(converted: converted, failures: failures)
        : converted.toString();
  }

  /// Format DV conversion timing in microseconds.
  String get dvAvgRpuConversionFormatted {
    final us = dvAvgRpuConversionUs;
    if (us == null || us <= 0) return t.common.notAvailable;
    return '${us}us';
  }

  /// Format DV sample processing timing in microseconds.
  String get dvAvgSampleProcessingFormatted {
    final us = dvAvgSampleProcessingUs;
    if (us == null || us <= 0) return t.common.notAvailable;
    return '${us}us';
  }

  /// Format app memory usage in MB.
  String get appMemoryFormatted {
    if (appMemoryBytes == null) return t.common.notAvailable;
    final mb = appMemoryBytes! / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Format UI FPS with 1 decimal place.
  String get uiFpsFormatted {
    if (uiFps == null) return t.common.notAvailable;
    return uiFps!.toStringAsFixed(1);
  }

  /// Format rotation in degrees.
  String get rotateFormatted {
    if (rotate == null || rotate == 0) return t.common.notAvailable;
    return '$rotate°';
  }

  /// Format luminance value in cd/m².
  String get maxLumaFormatted {
    if (maxLuma == null) return t.common.notAvailable;
    return '${maxLuma!.toStringAsFixed(0)} cd/m²';
  }

  /// Format minimum luminance value in cd/m².
  String get minLumaFormatted {
    if (minLuma == null) return t.common.notAvailable;
    return '${minLuma!.toStringAsFixed(4)} cd/m²';
  }

  /// Format MaxCLL value in cd/m².
  String get maxCllFormatted {
    if (maxCll == null) return t.common.notAvailable;
    return '${maxCll!.toStringAsFixed(0)} cd/m²';
  }

  /// Format MaxFALL value in cd/m².
  String get maxFallFormatted {
    if (maxFall == null) return t.common.notAvailable;
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

  bool get hasValidBufferLimits => bufferMaxMs != null && bufferMaxMs! > 0;

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
