import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../i18n/strings.g.dart';
import '../media/media_display_criteria.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../mpv/models.dart';
import '../mpv/player/player.dart';
import 'settings_service.dart';

part 'clip_export/clip_export_models.dart';
part 'clip_export/clip_export_runners.dart';

class ClipExportService {
  final ClipExportRunner? exportRunner;
  final Future<Directory> Function() _clipsDirectoryProvider;

  ClipExportRunner? _activeRunner;
  bool _cancelRequested = false;
  bool _disposed = false;

  final ValueNotifier<ClipExportJobState> state = ValueNotifier<ClipExportJobState>(const ClipExportJobState.idle());

  ClipExportService({this.exportRunner, Future<Directory> Function()? clipsDirectoryProvider})
    : _clipsDirectoryProvider = clipsDirectoryProvider ?? clipDirectory;

  static ClipSelection defaultSelection({
    required Duration position,
    required Duration duration,
    Duration lookback = clipDefaultLookback,
  }) {
    final safeDuration = duration < Duration.zero ? Duration.zero : duration;
    var end = position < Duration.zero ? Duration.zero : position;
    if (safeDuration > Duration.zero && end > safeDuration) end = safeDuration;
    var start = end - lookback;
    if (start < Duration.zero) start = Duration.zero;
    return ClipSelection(start: start, end: end);
  }

  static List<ClipExportFormat> formatsForOperatingSystem(String operatingSystem, {ClipSource? source}) {
    if (operatingSystem == 'macos' || operatingSystem == 'windows') {
      return [
        ClipExportFormat.hevcSdr,
        ClipExportFormat.h264Sdr,
        if (source?.canEncodeHdr == true) ClipExportFormat.hevcHdr,
        if (operatingSystem == 'macos') ClipExportFormat.gif,
        ClipExportFormat.source,
      ];
    }
    return const [ClipExportFormat.source];
  }

  static ClipExportFormat defaultFormatForOperatingSystem(String operatingSystem, {ClipSource? source}) {
    return formatsForOperatingSystem(operatingSystem, source: source).first;
  }

  static ClipSelection trimWindowForSelection({
    required Duration sourceDuration,
    required ClipSelection selection,
    Duration before = clipTrimWindowBefore,
    Duration after = clipTrimWindowAfter,
  }) {
    final clamped = selection.clampedTo(sourceDuration);
    final start = clamped.start - before;
    final end = clamped.end + after;
    return ClipSelection(
      start: start.isNegative ? Duration.zero : start,
      end: end > sourceDuration ? sourceDuration : end,
    );
  }

  static Duration sourceStartForPosition(ClipSource source, Duration position) {
    if (source.isTranscoding && position < source.timelineOffset) {
      throw ClipExportException(t.videoControls.clip.transcodeStartUnavailable);
    }
    final offset = source.isTranscoding ? source.timelineOffset : Duration.zero;
    final mapped = position - offset;
    return mapped < Duration.zero ? Duration.zero : mapped;
  }

  static Future<Directory> clipDirectory() => _captureDirectory(SettingsService.customClipPath);

  static Future<Directory> screenshotDirectory() => _captureDirectory(SettingsService.customScreenshotPath);

  static Future<Directory> _captureDirectory(NullableStringPref preference) async {
    final customPath = SettingsService.instanceOrNull?.read(preference);
    if (customPath != null) {
      try {
        return await _ensureDirectory(Directory(customPath));
      } catch (_) {
        // Fall back to Desktop if the configured folder is no longer available.
      }
    }

    final desktopDir = desktopDirectoryFromEnvironment(
      operatingSystem: Platform.operatingSystem,
      environment: Platform.environment,
    );
    if (desktopDir != null) {
      try {
        return await _ensureDirectory(desktopDir);
      } catch (_) {
        // Fall back to app support if Desktop cannot be resolved or created.
      }
    }

    final baseDir = await getApplicationSupportDirectory();
    return _ensureDirectory(Directory(path.join(baseDir.path, 'Plezy Clips')));
  }

  static bool isUsingCustomPath(NullableStringPref preference) =>
      SettingsService.instanceOrNull?.read(preference) != null;

  static Future<bool> isDirectoryWritable(Directory directory) async {
    File? probe;
    try {
      await _ensureDirectory(directory);
      probe = File(path.join(directory.path, '.plezy_write_test_${DateTime.now().microsecondsSinceEpoch}'));
      await probe.writeAsString('test', flush: true);
      await probe.delete();
      return true;
    } catch (_) {
      try {
        if (probe != null && await probe.exists()) await probe.delete();
      } catch (_) {}
      return false;
    }
  }

  @visibleForTesting
  static Directory? desktopDirectoryFromEnvironment({
    required String operatingSystem,
    required Map<String, String> environment,
  }) {
    final home = operatingSystem == 'windows'
        ? environment['USERPROFILE'] ?? _windowsHomeFromDriveAndPath(environment)
        : environment['HOME'];
    if (home == null || home.trim().isEmpty) return null;
    final pathContext = operatingSystem == 'windows'
        ? path.Context(style: path.Style.windows)
        : path.Context(style: path.Style.posix);
    return Directory(pathContext.join(home, 'Desktop'));
  }

  static String? _windowsHomeFromDriveAndPath(Map<String, String> environment) {
    final drive = environment['HOMEDRIVE'];
    final homePath = environment['HOMEPATH'];
    if (drive == null || drive.isEmpty || homePath == null || homePath.isEmpty) return null;
    return '$drive$homePath';
  }

  static String buildClipFileName(
    ClipSource source,
    ClipSelection selection, {
    ClipExportFormat format = ClipExportFormat.hevcSdr,
  }) {
    final base = _metadataFileNameBase(source);
    final range = '${formatClipTimestamp(selection.start)}-${formatClipTimestamp(selection.end)}';
    final extension = switch (format) {
      ClipExportFormat.source => sourceFileExtension(source),
      ClipExportFormat.gif => 'gif',
      _ => 'mp4',
    };
    return '${base.isEmpty ? 'Clip' : base} - $range.$extension';
  }

  static String buildScreenshotFileName(ClipSource source, Duration position) {
    final base = _metadataFileNameBase(source);
    return '${base.isEmpty ? 'Clip' : base} - ${formatClipTimestamp(position)}.png';
  }

  static Future<File> createScreenshotOutputFile(
    ClipSource source,
    Duration position, {
    Future<Directory> Function()? directoryProvider,
  }) async {
    final directory = await _ensureDirectory(await (directoryProvider ?? screenshotDirectory)());
    return _uniqueOutputFile(directory, buildScreenshotFileName(source, position));
  }

  static String _metadataFileNameBase(ClipSource source) {
    final title = sanitizeClipFileName(source.title);
    final subtitle = source.subtitle == null ? '' : sanitizeClipFileName(source.subtitle!);
    return <String>[title, if (subtitle.isNotEmpty) subtitle].where((part) => part.isNotEmpty).join(' - ');
  }

  @visibleForTesting
  static String sourceFileExtension(ClipSource source) {
    final uriPath = Uri.tryParse(source.uri)?.path ?? source.uri;
    final uriExtension = path.extension(uriPath).replaceFirst('.', '').toLowerCase();
    if (source.isTranscoding && uriExtension == 'm3u8') return 'ts';

    for (final candidate in [source.container, uriExtension]) {
      final extension = _normalizeSourceExtension(candidate);
      if (extension != null) return extension;
    }
    return 'media';
  }

  static String sanitizeClipFileName(String value) {
    final sanitized = value
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .replaceAll(RegExp(r'[. ]+$'), '');
    if (sanitized.isEmpty) return 'Clip';
    return sanitized.length <= 140 ? sanitized : sanitized.substring(0, 140).trimRight();
  }

  static String formatClipTimestamp(Duration value) {
    final totalSeconds = value.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}h${minutes.toString().padLeft(2, '0')}m${seconds.toString().padLeft(2, '0')}s';
    }
    return '${minutes.toString().padLeft(2, '0')}m${seconds.toString().padLeft(2, '0')}s';
  }

  static ({String title, String? subtitle}) metadataLabels(MediaItem metadata) {
    final title = metadata.displayTitle.isNotEmpty ? metadata.displayTitle : metadata.title ?? 'Clip';
    if (metadata.kind == MediaKind.episode) {
      final season = metadata.parentIndex;
      final episode = metadata.index;
      if (season != null && episode != null) {
        return (title: title, subtitle: 'S${season.toString().padLeft(2, '0')}E${episode.toString().padLeft(2, '0')}');
      }
    }
    return (title: title, subtitle: metadata.displaySubtitle);
  }

  Future<String> exportClip({
    required ClipSource source,
    required ClipSelection selection,
    ClipExportFormat? format,
    GifExportResolution gifResolution = GifExportResolution.automatic,
    bool subtitlesEnabled = false,
    Player? player,
  }) async {
    final clamped = selection.clampedTo(source.duration);
    clamped.validate(source.duration);

    final selectedFormat = format ?? defaultFormatForOperatingSystem(Platform.operatingSystem, source: source);
    if (selectedFormat == ClipExportFormat.source && subtitlesEnabled) {
      throw ClipExportException(t.videoControls.clip.sourceCopyNoEncoder);
    }
    final clipsDirectory = await _clipsDirectoryProvider();
    final outputFile = await _uniqueOutputFile(
      clipsDirectory,
      buildClipFileName(source, clamped, format: selectedFormat),
    );
    final sourceStart = sourceStartForPosition(source, clamped.start);
    final sourceEnd = sourceStartForPosition(source, clamped.end);

    _cancelRequested = false;
    _setState(const ClipExportJobState(stage: ClipExportStage.running, progress: 0));

    final runner =
        exportRunner ??
        (selectedFormat == ClipExportFormat.source
            ? (player == null ? null : MpvClipExportRunner(player))
            : MpvEncodingClipExportRunner(
                source: source,
                format: selectedFormat,
                gifResolution: gifResolution,
                subtitlesEnabled: subtitlesEnabled,
              ));
    _activeRunner = runner;
    try {
      if (runner == null) {
        throw ClipExportException(t.videoControls.clip.previewRequired);
      }
      await runner.export(start: sourceStart, end: sourceEnd, outputPath: outputFile.path, onProgress: _updateProgress);
      _activeRunner = null;

      if (_cancelRequested) {
        _setState(const ClipExportJobState(stage: ClipExportStage.canceled));
        throw ClipExportException(t.videoControls.clip.exportCanceled);
      }
      if (!await outputFile.exists() || await outputFile.length() == 0) {
        throw ClipExportException(_failureMessage(selectedFormat));
      }
      _setState(const ClipExportJobState(stage: ClipExportStage.completed, progress: 1));
      return outputFile.path;
    } catch (error) {
      _activeRunner = null;
      if (_cancelRequested) {
        await _deleteIfExists(outputFile);
        _setState(const ClipExportJobState(stage: ClipExportStage.canceled));
        throw ClipExportException(t.videoControls.clip.exportCanceled);
      }
      await _deleteIfExists(outputFile);
      final message = error is ClipExportException ? error.message : _failureMessage(selectedFormat);
      final exception = error is ClipExportException ? error : ClipExportException(message);
      _setState(const ClipExportJobState(stage: ClipExportStage.failed));
      throw exception;
    }
  }

  Future<void> cancelActiveExport() async {
    _cancelRequested = true;
    await _activeRunner?.cancel();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _cancelRequested = true;
    unawaited(_activeRunner?.cancel());
    state.dispose();
  }

  void _updateProgress(double progress) {
    if (_disposed) return;
    if (state.value.stage != ClipExportStage.running) return;
    _setState(ClipExportJobState(stage: ClipExportStage.running, progress: progress.clamp(0.0, 0.99).toDouble()));
  }

  void _setState(ClipExportJobState next) {
    if (!_disposed) state.value = next;
  }

  static Future<Directory> _ensureDirectory(Directory directory) async {
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  static Future<File> _uniqueOutputFile(Directory directory, String fileName) async {
    final extension = path.extension(fileName);
    final base = path.basenameWithoutExtension(fileName);
    var candidate = File(path.join(directory.path, fileName));
    var counter = 2;
    while (await candidate.exists()) {
      candidate = File(path.join(directory.path, '$base ($counter)$extension'));
      counter++;
    }
    return candidate;
  }

  static String _failureMessage(ClipExportFormat format) {
    return switch (format) {
      ClipExportFormat.h264Sdr => t.videoControls.clip.h264Failed,
      ClipExportFormat.hevcSdr => t.videoControls.clip.hevcSdrFailed,
      ClipExportFormat.hevcHdr => t.videoControls.clip.hevcHdrFailed,
      ClipExportFormat.gif => t.videoControls.clip.gifFailed,
      ClipExportFormat.source => t.videoControls.clip.originalFailed,
    };
  }

  static Future<void> _deleteIfExists(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Preserve the original export error if cleanup fails.
    }
  }
}

String? _normalizeSourceExtension(String? value) {
  final normalized = value?.trim().toLowerCase().replaceFirst(RegExp(r'^\.'), '');
  return switch (normalized) {
    'matroska' || 'mkv' => 'mkv',
    'mpegts' || 'mpeg-ts' || 'm3u8' || 'ts' => 'ts',
    'quicktime' || 'mov' => 'mov',
    'mp4' || 'm4v' || 'webm' || 'avi' || 'm2ts' => normalized,
    _ => null,
  };
}
