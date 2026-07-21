part of '../clip_export_service.dart';

abstract class ClipExportRunner {
  Future<void> export({
    required Duration start,
    required Duration end,
    required String outputPath,
    required ValueChanged<double> onProgress,
  });

  Future<void> cancel();
}

class MpvClipExportRunner implements ClipExportRunner {
  final Player player;
  bool _canceled = false;

  MpvClipExportRunner(this.player);

  @visibleForTesting
  static List<String> buildDumpCacheCommand({
    required Duration start,
    required Duration end,
    required String outputPath,
  }) {
    return ['dump-cache', _formatMpvTime(start), _formatMpvTime(end), outputPath];
  }

  @visibleForTesting
  static bool cacheRangesCoverSelection({
    required List<BufferRange> ranges,
    required Duration start,
    required Duration end,
    Duration tolerance = const Duration(milliseconds: 150),
  }) {
    if (end <= start) return false;
    return _contiguousCachedEnd(ranges, start, tolerance: tolerance) + tolerance >= end;
  }

  @override
  Future<void> export({
    required Duration start,
    required Duration end,
    required String outputPath,
    required ValueChanged<double> onProgress,
  }) async {
    _canceled = false;
    await _waitForCache(start: start, end: end, onProgress: onProgress);
    if (_canceled) throw ClipExportException(t.videoControls.clip.exportCanceled);

    onProgress(0.95);
    await player.command(buildDumpCacheCommand(start: start, end: end, outputPath: outputPath));
  }

  @override
  Future<void> cancel() async {
    _canceled = true;
    try {
      await player.command(const ['dump-cache', '0', 'no', '']);
    } catch (_) {
      // The player may already be closing.
    }
  }

  Future<void> _waitForCache({
    required Duration start,
    required Duration end,
    required ValueChanged<double> onProgress,
  }) async {
    final timelineOffset = player is PlayerBase ? (player as PlayerBase).timelineOffset : Duration.zero;
    final timelineStart = start + timelineOffset;
    final timelineEnd = end + timelineOffset;
    final totalMicros = (timelineEnd - timelineStart).inMicroseconds;
    if (totalMicros <= 0) return;

    await player.pause();
    await player.seek(timelineStart);

    final deadline = DateTime.now().add(const Duration(minutes: 5));

    while (!_canceled) {
      final ranges = player.state.bufferRanges;
      final coveredUntil = _contiguousCachedEnd(ranges, timelineStart);
      final coveredMicros = (coveredUntil - timelineStart).inMicroseconds.clamp(0, totalMicros);
      onProgress((coveredMicros / totalMicros) * 0.9);
      if (cacheRangesCoverSelection(ranges: ranges, start: timelineStart, end: timelineEnd)) return;

      if (DateTime.now().isAfter(deadline)) {
        throw ClipExportException(t.videoControls.clip.cacheUnavailable);
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }

    throw ClipExportException(t.videoControls.clip.exportCanceled);
  }

  static Duration _contiguousCachedEnd(
    List<BufferRange> ranges,
    Duration start, {
    Duration tolerance = const Duration(milliseconds: 150),
  }) {
    var coveredUntil = start;
    final sorted = [...ranges]..sort((a, b) => a.start.compareTo(b.start));
    for (final range in sorted) {
      if (range.end + tolerance < coveredUntil) continue;
      if (range.start - tolerance > coveredUntil) break;
      if (range.end > coveredUntil) coveredUntil = range.end;
    }
    return coveredUntil;
  }
}

typedef ClipEncoderPlayerFactory = Player Function(Map<String, String> initialOptions);

const int _gifMaximumBytes = 10000000;
const int _gifRetryTargetBytes = 9500000;
const int _gifMaximumFramesPerSecond = 20;
const int _gifMinimumFramesPerSecond = 10;

typedef _GifEncodingSettings = ({int framesPerSecond, int maxWidth, int maxHeight});

typedef ClipEncodingPassRunner =
    Future<void> Function({
      required Map<String, String> initialOptions,
      required Duration start,
      required Duration end,
      required ValueChanged<double> onProgress,
    });

class MpvEncodingClipExportRunner implements ClipExportRunner {
  final ClipSource source;
  final ClipExportFormat format;
  final GifExportResolution gifResolution;
  final bool subtitlesEnabled;
  final String operatingSystem;
  final ClipEncoderPlayerFactory _playerFactory;
  final ClipEncodingPassRunner? encodingPassRunner;

  Player? _player;
  Completer<void>? _completion;
  bool _canceled = false;

  MpvEncodingClipExportRunner({
    required this.source,
    required this.format,
    this.gifResolution = GifExportResolution.automatic,
    this.subtitlesEnabled = false,
    String? operatingSystem,
    ClipEncoderPlayerFactory? playerFactory,
    this.encodingPassRunner,
  }) : operatingSystem = operatingSystem ?? Platform.operatingSystem,
       _playerFactory = playerFactory ?? Player.clipEncoder;

  @visibleForTesting
  static Map<String, String> buildInitialOptions({
    required String operatingSystem,
    required ClipExportFormat format,
    required ClipSource source,
    required Duration start,
    required Duration end,
    required String outputPath,
    int gifFramesPerSecond = _gifMaximumFramesPerSecond,
    int gifMaxWidth = 1920,
    int gifMaxHeight = 1080,
    bool subtitlesEnabled = false,
  }) {
    if (format == ClipExportFormat.source) {
      throw ClipExportException(t.videoControls.clip.sourceCopyNoEncoder);
    }

    final isMacOS = operatingSystem == 'macos';
    final isWindows = operatingSystem == 'windows';
    if (!isMacOS && !isWindows) {
      throw ClipExportException(t.videoControls.clip.encodingDesktopOnly);
    }

    if (format == ClipExportFormat.gif) {
      if (!isMacOS) throw ClipExportException(t.videoControls.clip.gifFailed);
      final burnSubtitles = subtitlesEnabled && source.hasSubtitleTrack;
      final frameFilter =
          "lavfi=[fps=$gifFramesPerSecond,scale=w='min(iw,$gifMaxWidth)':"
          "h='min(ih,$gifMaxHeight)':force_original_aspect_ratio=decrease:"
          'force_divisible_by=2:flags=lanczos]';
      final options = <String, String>{
        'o': outputPath,
        'of': 'gif',
        'ovc': 'gif',
        'ofopts': 'loop=0',
        'aid': 'no',
        'start': _formatMpvTime(start),
        'end': _formatMpvTime(end),
        'sid': 'no',
        'secondary-sid': 'no',
        'keep-open': 'no',
        'ocopy-metadata': 'no',
        'hwdec': 'no',
      };
      if (burnSubtitles) options['blend-subtitles'] = 'video';
      if (source.colorType != MediaDisplayColorType.sdr) {
        options
          ..['vf'] = 'gpu=api=vulkan,$frameFilter,$_sdrFormatFilter'
          ..['target-prim'] = 'bt.709'
          ..['target-trc'] = 'bt.1886'
          ..['target-peak'] = '203'
          ..['tone-mapping'] = 'mobius'
          ..['hdr-compute-peak'] = 'yes';
      } else {
        options['vf'] = '${burnSubtitles ? 'gpu=api=vulkan,' : ''}$frameFilter,$_sdrFormatFilter';
      }
      return options;
    }

    if (format == ClipExportFormat.hevcHdr && !source.canEncodeHdr) {
      throw ClipExportException(t.videoControls.clip.hdrRequiresSource);
    }

    final isH264 = format == ClipExportFormat.h264Sdr;
    final isHdrOutput = format == ClipExportFormat.hevcHdr;
    final burnSubtitles = subtitlesEnabled && source.hasSubtitleTrack;
    final colorOptions = isHdrOutput ? _hdrColorOptions(source.colorType) : _sdrColorOptions;
    final videoCodecOptions = isMacOS
        ? _macOsVideoCodecOptions(isH264: isH264, isHdr: isHdrOutput, colorOptions: colorOptions)
        : _windowsVideoCodecOptions(isH264: isH264, isHdr: isHdrOutput, colorOptions: colorOptions);
    final options = <String, String>{
      'o': outputPath,
      'of': 'mp4',
      'ovc': isMacOS ? (isH264 ? 'h264_videotoolbox' : 'hevc_videotoolbox') : (isH264 ? 'libx264' : 'libx265'),
      'ovcopts': isH264 ? videoCodecOptions : '$videoCodecOptions,codec_tag=$_hvc1CodecTag',
      'oac': isMacOS ? 'aac_at' : 'aac',
      'oacopts': 'b=192000',
      'ofopts': 'movflags=+faststart',
      'start': _formatMpvTime(start),
      'end': _formatMpvTime(end),
      'sid': 'no',
      'secondary-sid': 'no',
      'keep-open': 'no',
      'ocopy-metadata': 'no',
      'audio-channels': 'stereo',
      'hwdec': 'no',
    };
    if (burnSubtitles) options['blend-subtitles'] = 'video';

    if (isHdrOutput) {
      options['vf'] = '${burnSubtitles ? 'gpu=api=vulkan,' : ''}${_hdrFormatFilter(source.colorType)}';
      if (burnSubtitles) {
        options
          ..['target-prim'] = 'bt.2020'
          ..['target-trc'] = source.colorType == MediaDisplayColorType.hlg ? 'hlg' : 'pq';
      }
    } else if (source.colorType != MediaDisplayColorType.sdr) {
      options
        ..['vf'] = _hdrToSdrFilter
        ..['target-prim'] = 'bt.709'
        ..['target-trc'] = 'bt.1886'
        ..['target-peak'] = '203'
        ..['tone-mapping'] = 'mobius'
        ..['hdr-compute-peak'] = 'yes';
    } else {
      options['vf'] = '${burnSubtitles ? 'gpu=api=vulkan,' : ''}$_sdrFormatFilter';
    }
    return options;
  }

  @override
  Future<void> export({
    required Duration start,
    required Duration end,
    required String outputPath,
    required ValueChanged<double> onProgress,
  }) async {
    _canceled = false;
    if (format == ClipExportFormat.gif) {
      await _exportGif(start: start, end: end, outputPath: outputPath, onProgress: onProgress);
      return;
    }
    await _encodeAttempt(start: start, end: end, outputPath: outputPath, onProgress: onProgress);
  }

  Future<void> _exportGif({
    required Duration start,
    required Duration end,
    required String outputPath,
    required ValueChanged<double> onProgress,
  }) async {
    if (operatingSystem != 'macos') throw ClipExportException(t.videoControls.clip.gifFailed);

    final temporaryFile = File('$outputPath.plezy-part');
    var settings = switch (gifResolution) {
      GifExportResolution.p480 => (framesPerSecond: _gifMaximumFramesPerSecond, maxWidth: 854, maxHeight: 480),
      GifExportResolution.p720 => (framesPerSecond: _gifMaximumFramesPerSecond, maxWidth: 1280, maxHeight: 720),
      GifExportResolution.automatic ||
      GifExportResolution.p1080 => (framesPerSecond: _gifMaximumFramesPerSecond, maxWidth: 1920, maxHeight: 1080),
    };
    var reportedProgress = 0.0;

    try {
      while (true) {
        await _deleteFileIfExists(temporaryFile);
        final attemptStart = reportedProgress;
        final attemptEnd = gifResolution == GifExportResolution.automatic
            ? attemptStart + ((0.99 - attemptStart) / 2)
            : 0.99;
        await _encodeAttempt(
          start: start,
          end: end,
          outputPath: temporaryFile.path,
          gifSettings: settings,
          onProgress: (progress) {
            final next = attemptStart + ((attemptEnd - attemptStart) * progress.clamp(0.0, 1.0));
            if (next > reportedProgress) {
              reportedProgress = next;
              onProgress(reportedProgress);
            }
          },
        );
        if (_canceled) throw ClipExportException(t.videoControls.clip.exportCanceled);
        if (!await temporaryFile.exists()) throw ClipExportException(t.videoControls.clip.gifFailed);

        final actualBytes = await temporaryFile.length();
        if (actualBytes <= 0) throw ClipExportException(t.videoControls.clip.gifFailed);
        if (gifResolution != GifExportResolution.automatic || actualBytes <= _gifMaximumBytes) {
          await temporaryFile.rename(outputPath);
          onProgress(0.99);
          return;
        }
        settings = _nextGifSettings(settings, actualBytes);
      }
    } finally {
      await _deleteFileIfExists(temporaryFile);
    }
  }

  Future<void> _encodeAttempt({
    required Duration start,
    required Duration end,
    required String outputPath,
    required ValueChanged<double> onProgress,
    _GifEncodingSettings? gifSettings,
  }) async {
    final initialOptions = buildInitialOptions(
      operatingSystem: operatingSystem,
      format: format,
      source: source,
      start: start,
      end: end,
      outputPath: outputPath,
      gifFramesPerSecond: gifSettings?.framesPerSecond ?? _gifMaximumFramesPerSecond,
      gifMaxWidth: gifSettings?.maxWidth ?? 1920,
      gifMaxHeight: gifSettings?.maxHeight ?? 1080,
      subtitlesEnabled: subtitlesEnabled,
    );
    await (encodingPassRunner ?? _runEncodingPass)(
      initialOptions: initialOptions,
      start: start,
      end: end,
      onProgress: onProgress,
    );
  }

  Future<void> _runEncodingPass({
    required Map<String, String> initialOptions,
    required Duration start,
    required Duration end,
    required ValueChanged<double> onProgress,
  }) async {
    final player = _playerFactory(initialOptions);
    final completion = Completer<void>();
    _completion = completion;
    _player = player;
    final durationMicros = (end - start).inMicroseconds;

    final subscriptions = <StreamSubscription<dynamic>>[
      player.streams.completed.listen((completed) {
        if (completed && !completion.isCompleted) completion.complete();
      }),
      player.streams.error.listen((error) {
        if (!completion.isCompleted) completion.completeError(ClipExportException(error.message));
      }),
      player.streams.position.listen((position) {
        if (durationMicros <= 0) return;
        final progress = ((position - start).inMicroseconds / durationMicros).clamp(0.0, 0.99).toDouble();
        onProgress(progress);
      }),
    ];

    try {
      onProgress(0);
      final subtitle = subtitlesEnabled ? source.subtitleTrack : null;
      final externalSubtitle = subtitle?.uri == null ? null : [subtitle!];
      await player.open(
        Media(source.uri, headers: source.headers, start: start),
        play: false,
        externalSubtitles: externalSubtitle,
      );
      if (format != ClipExportFormat.gif && source.audioTrack != null) {
        await player.selectAudioTrack(source.audioTrack!);
      }
      if (subtitle != null) {
        await player.selectSubtitleTrack(subtitle.uri == null ? subtitle : SubtitleTrack.auto);
        await player.setProperty('sub-visibility', 'yes');
      }
      await player.play();
      await completion.future;
      if (_canceled) throw ClipExportException(t.videoControls.clip.exportCanceled);
    } finally {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
      await player.dispose();
      _player = null;
      _completion = null;
    }
  }

  @override
  Future<void> cancel() async {
    _canceled = true;
    final completion = _completion;
    if (completion != null && !completion.isCompleted) {
      completion.completeError(ClipExportException(t.videoControls.clip.exportCanceled));
    }
    try {
      await _player?.stop();
    } catch (_) {
      // The encoder may already be finishing.
    }
  }
}

_GifEncodingSettings _nextGifSettings(_GifEncodingSettings current, int actualBytes) {
  final ratio = _gifRetryTargetBytes / actualBytes;
  if (current.framesPerSecond > _gifMinimumFramesPerSecond) {
    return (
      framesPerSecond: (current.framesPerSecond * ratio).floor().clamp(
        _gifMinimumFramesPerSecond,
        current.framesPerSecond - 1,
      ),
      maxWidth: current.maxWidth,
      maxHeight: current.maxHeight,
    );
  }

  if (current.maxWidth <= 2 && current.maxHeight <= 2) {
    throw ClipExportException(t.videoControls.clip.gifFailed);
  }
  final scale = math.min(math.sqrt(ratio), 0.95);
  return (
    framesPerSecond: _gifMinimumFramesPerSecond,
    maxWidth: _smallerEvenDimension(current.maxWidth, scale),
    maxHeight: _smallerEvenDimension(current.maxHeight, scale),
  );
}

int _smallerEvenDimension(int current, double scale) {
  var next = (current * scale).floor();
  if (next.isOdd) next--;
  if (next >= current) next = current - 2;
  return math.max(2, next);
}

Future<void> _deleteFileIfExists(File file) async {
  try {
    if (await file.exists()) await file.delete();
  } catch (_) {
    // Preserve the export result if best-effort temporary cleanup fails.
  }
}

const String _sdrFormatFilter =
    'format=fmt=yuv420p:colormatrix=bt.709:colorlevels=limited:'
    'primaries=bt.709:gamma=bt.1886:convert=yes';

const String _hdrToSdrFilter = 'gpu=api=vulkan,$_sdrFormatFilter';

const String _sdrColorOptions = 'color_primaries=1,color_trc=1,colorspace=1,color_range=1,pixel_format=yuv420p';

// Little-endian integer representation of the MP4 `hvc1` sample-entry tag.
const String _hvc1CodecTag = '828601960';

String _hdrFormatFilter(MediaDisplayColorType colorType) {
  final transfer = colorType == MediaDisplayColorType.hlg ? 'hlg' : 'pq';
  return 'format=fmt=p010:colormatrix=bt.2020-ncl:colorlevels=limited:'
      'primaries=bt.2020:gamma=$transfer:convert=yes';
}

String _hdrColorOptions(MediaDisplayColorType colorType) {
  final transfer = colorType == MediaDisplayColorType.hlg ? 18 : 16;
  return 'color_primaries=9,color_trc=$transfer,colorspace=9,color_range=1';
}

String _macOsVideoCodecOptions({required bool isH264, required bool isHdr, required String colorOptions}) {
  final codec = isH264
      ? 'b=8000000,profile=high'
      : isHdr
      ? 'b=8000000,profile=main10'
      : 'b=5000000,profile=main';
  final pixelFormat = isHdr ? ',pixel_format=p010le' : '';
  return '$codec,$colorOptions$pixelFormat';
}

String _windowsVideoCodecOptions({required bool isH264, required bool isHdr, required String colorOptions}) {
  final codec = isH264
      ? 'crf=20,preset=veryfast'
      : isHdr
      ? 'crf=20,preset=fast,profile=main10'
      : 'crf=24,preset=fast';
  final pixelFormat = isHdr ? ',pixel_format=yuv420p10le' : '';
  return '$codec,$colorOptions$pixelFormat';
}

String _formatMpvTime(Duration value) {
  final micros = value.inMicroseconds;
  if (micros <= 0) return '0';
  final seconds = micros / Duration.microsecondsPerSecond;
  final text = seconds.toStringAsFixed(3);
  return text.replaceFirst(RegExp(r'\.?0+$'), '');
}
