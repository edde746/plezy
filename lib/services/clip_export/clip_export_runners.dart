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

  @override
  Future<void> export({
    required Duration start,
    required Duration end,
    required String outputPath,
    required ValueChanged<double> onProgress,
  }) async {
    _canceled = false;
    await _waitForCache(start: start, end: end, onProgress: onProgress);
    if (_canceled) throw const ClipExportException('Clip export canceled.');

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
    final startSeconds = start.inMicroseconds / Duration.microsecondsPerSecond;
    final endSeconds = end.inMicroseconds / Duration.microsecondsPerSecond;
    final totalSeconds = endSeconds - startSeconds;
    if (totalSeconds <= 0) return;

    final deadline = DateTime.now().add(const Duration(minutes: 5));
    var unavailableReads = 0;

    while (!_canceled) {
      String? rawCacheEnd;
      try {
        rawCacheEnd = await player.getProperty('demuxer-cache-time');
      } catch (_) {
        return;
      }

      final cacheEnd = double.tryParse(rawCacheEnd ?? '');
      if (cacheEnd == null) {
        unavailableReads++;
        if (unavailableReads >= 4) return;
      } else {
        unavailableReads = 0;
        final fraction = ((cacheEnd - startSeconds) / totalSeconds).clamp(0.0, 1.0);
        onProgress(fraction * 0.9);
        if (cacheEnd + 0.1 >= endSeconds) return;
      }

      if (DateTime.now().isAfter(deadline)) {
        throw const ClipExportException(
          'The selected range could not be cached for export. Try a shorter clip or wait for the preview to load.',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }

    throw const ClipExportException('Clip export canceled.');
  }
}

typedef ClipEncoderPlayerFactory = Player Function(Map<String, String> initialOptions);

class MpvEncodingClipExportRunner implements ClipExportRunner {
  final ClipSource source;
  final ClipExportFormat format;
  final String operatingSystem;
  final ClipEncoderPlayerFactory _playerFactory;

  Player? _player;
  Completer<void>? _completion;
  bool _canceled = false;

  MpvEncodingClipExportRunner({
    required this.source,
    required this.format,
    String? operatingSystem,
    ClipEncoderPlayerFactory? playerFactory,
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
  }) {
    if (format == ClipExportFormat.source) {
      throw const ClipExportException('Source-copy export does not use an encoder.');
    }

    final isMacOS = operatingSystem == 'macos';
    final isWindows = operatingSystem == 'windows';
    if (!isMacOS && !isWindows) {
      throw const ClipExportException('H.264 and HEVC clip encoding is currently available on macOS and Windows.');
    }

    if (format == ClipExportFormat.hevcHdr && !source.canEncodeHdr) {
      throw const ClipExportException('HDR export requires a direct-play HDR10 or HLG-compatible source.');
    }

    final isH264 = format == ClipExportFormat.h264Sdr;
    final isHdrOutput = format == ClipExportFormat.hevcHdr;
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

    if (isHdrOutput) {
      options['vf'] = _hdrFormatFilter(source.colorType);
    } else if (source.colorType != MediaDisplayColorType.sdr) {
      options
        ..['vf'] = _hdrToSdrFilter
        ..['target-prim'] = 'bt.709'
        ..['target-trc'] = 'bt.1886'
        ..['target-peak'] = '203'
        ..['tone-mapping'] = 'mobius'
        ..['hdr-compute-peak'] = 'yes';
    } else {
      options['vf'] = _sdrFormatFilter;
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
    final initialOptions = buildInitialOptions(
      operatingSystem: operatingSystem,
      format: format,
      source: source,
      start: start,
      end: end,
      outputPath: outputPath,
    );
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
      await player.open(Media(source.uri, headers: source.headers, start: start), play: true);
      await completion.future;
      if (_canceled) throw const ClipExportException('Clip export canceled.');
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
      completion.completeError(const ClipExportException('Clip export canceled.'));
    }
    try {
      await _player?.stop();
    } catch (_) {
      // The encoder may already be finishing.
    }
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
