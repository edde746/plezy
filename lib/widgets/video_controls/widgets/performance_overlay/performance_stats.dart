import '../../../../i18n/strings.g.dart';
import '../../../../utils/codec_utils.dart';

/// What decodes a Dolby Vision file on Android mpv. Wire ids match the
/// Kotlin `GpuVoPolicy.DvRoute`.
enum DvRoute {
  /// The Dolby Vision MediaCodec decoder takes the stream as it is.
  dvDecoder('dv-decoder'),

  /// Profile 7 converted to 8.1 for a profile 8 Dolby Vision decoder.
  dvDecoderP81('dv-decoder-p81'),

  /// No Dolby Vision decoder: the base layer decodes on its own.
  baseLayer('base-layer'),

  /// Software decode on gpu-next, which applies the RPU itself.
  reshaped('reshaped');

  const DvRoute(this.id);

  final String id;

  /// Null for an absent or unknown id, which hides the row.
  static DvRoute? fromId(String? id) {
    for (final route in values) {
      if (route.id == id) return route;
    }
    return null;
  }
}

/// Data model for video player performance statistics.
///
/// Contains metrics queried from the mpv player, including video/audio codec
/// info, playback performance, and buffer state.
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

  /// mpv `audio-params/format` when it names an IEC 61937 bitstream
  /// ('spdif-eac3'); null when audio is decoded locally.
  final String? audioPassthroughFormat;

  final double? actualFps;
  final double? avsyncChange;
  final double? displayFps;
  final int? frameDropCount;
  final int? decoderFrameDropCount;

  final int? cacheUsed;
  final int? cacheLimit;
  final double? cacheSpeed;
  final double? cacheDuration;

  final int? dvSourceProfile;

  /// Android mpv's Dolby Vision route.
  final DvRoute? dvRoute;

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
    this.audioPassthroughFormat,
    this.actualFps,
    this.avsyncChange,
    this.displayFps,
    this.frameDropCount,
    this.decoderFrameDropCount,
    this.cacheUsed,
    this.cacheLimit,
    this.cacheSpeed,
    this.cacheDuration,
    this.dvSourceProfile,
    this.dvRoute,
    this.appMemoryBytes,
    this.uiFps,
  });

  /// Creates an empty stats object (used as initial state).
  const PerformanceStats.empty() : this();

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

  String get audioBitrateFormatted {
    if (audioBitrate == null || audioBitrate == 0) return t.common.notAvailable;
    final kbps = audioBitrate! / 1000;
    return '${kbps.toStringAsFixed(0)} kbps';
  }

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

  String get cacheUsedFormatted {
    if (cacheUsed == null) return t.common.notAvailable;
    final mb = cacheUsed! / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Format the resident cache ceiling in MB.
  ///
  /// [cacheLimit] is the forward *plus* back demuxer bound: with
  /// `demuxer-donate-buffer` (on by default) the back cache absorbs forward
  /// bytes the reader has not claimed, so the sum is the only number that
  /// bounds what the process holds.
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

  String get displayFpsFormatted {
    if (displayFps == null) return t.common.notAvailable;
    return displayFps!.toStringAsFixed(0);
  }

  /// Format dropped frames count.
  ///
  /// `frame-drop-count` is the video output's own count. A GL vo drops a
  /// frame that is a whole duration late on admission; the fork's
  /// `vo_mediacodec` never drops, so it counts what the viewer sees instead:
  /// a frame that was due before it reached the codec, and a timed frame the
  /// display confirms it showed off its vsync (Android 13+ feedback).
  /// `decoder-frame-drop-count` is the `--framedrop=decoder` path.
  String get droppedFramesFormatted {
    final total = (frameDropCount ?? 0) + (decoderFrameDropCount ?? 0);
    return total.toString();
  }

  /// Format hardware decoding mode.
  String get hwdecFormatted {
    if (hwdecCurrent == null || hwdecCurrent!.isEmpty || hwdecCurrent == 'no') {
      return t.performanceOverlay.decoderSoftware;
    }
    return hwdecCurrent!;
  }

  String get dvSourceProfileFormatted => dvSourceProfile == null ? t.common.notAvailable : 'P$dvSourceProfile';

  /// Format Dolby Vision playback path. mpv's base layer is named by the
  /// transfer it decodes to, so a P8.1 fallback reads as HDR10 (#2534).
  String get dvPlaybackPathFormatted => switch (dvRoute) {
    DvRoute.dvDecoder => t.performanceOverlay.dvRouteDecoder,
    DvRoute.dvDecoderP81 => t.performanceOverlay.dvRouteDecoderP81,
    DvRoute.reshaped => t.performanceOverlay.dvRouteReshaped,
    DvRoute.baseLayer => switch (gamma) {
      'pq' => t.performanceOverlay.dvRouteBaseLayerHdr10,
      'hlg' => t.performanceOverlay.dvRouteBaseLayerHlg,
      null || '' || 'auto' => t.performanceOverlay.dvRouteBaseLayer,
      _ => t.performanceOverlay.dvRouteBaseLayerSdr,
    },
    null => t.common.notAvailable,
  };

  bool get hasDvPlaybackPath => dvRoute != null;

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

  /// Check if audio bitrate is valid (not null, not negative, not zero).
  bool get hasValidAudioBitrate {
    return audioBitrate != null && audioBitrate! > 0;
  }

  String get playerTypeFormatted {
    return switch (playerType.toLowerCase()) {
      'mpv' => 'MPV',
      _ => playerType,
    };
  }
}
