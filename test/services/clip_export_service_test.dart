import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_display_criteria.dart';
import 'package:plezy/mpv/models.dart';
import 'package:plezy/services/clip_export_service.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/prefs.dart';

ClipSource _source({
  String uri = 'https://example.test/video.mp4',
  Map<String, String> headers = const {},
  bool isTranscoding = false,
  Duration timelineOffset = Duration.zero,
  Duration duration = const Duration(minutes: 10),
  String title = 'Show',
  String? subtitle = 'S01E02',
  String? container,
  MediaDisplayCriteria? displayCriteria,
}) {
  return ClipSource(
    uri: uri,
    headers: headers,
    isTranscoding: isTranscoding,
    timelineOffset: timelineOffset,
    duration: duration,
    title: title,
    subtitle: subtitle,
    container: container,
    displayCriteria: displayCriteria,
  );
}

const _pqCriteria = MediaDisplayCriteria(transfer: 'smpte2084', primaries: 'bt2020', matrix: 'bt2020nc');

const _hlgCriteria = MediaDisplayCriteria(transfer: 'arib-std-b67', primaries: 'bt2020', matrix: 'bt2020nc');

const _sdrCriteria = MediaDisplayCriteria(transfer: 'bt709', primaries: 'bt709', matrix: 'bt709');

const _dolbyVisionHdr10Criteria = MediaDisplayCriteria(doviProfile: 8, doviCompatibilityId: 1);

const _dolbyVisionOnlyCriteria = MediaDisplayCriteria(doviProfile: 5);

Map<String, String> _encodingOptions(ClipExportFormat format, {String operatingSystem = 'macos', ClipSource? source}) {
  return MpvEncodingClipExportRunner.buildInitialOptions(
    operatingSystem: operatingSystem,
    format: format,
    source: source ?? _source(),
    start: const Duration(seconds: 30),
    end: const Duration(seconds: 60),
    outputPath: '/tmp/clip.mp4',
  );
}

class _FakeClipExportRunner implements ClipExportRunner {
  final _completion = Completer<void>();
  late Duration start;
  late Duration end;
  late String outputPath;
  late ValueChanged<double> _onProgress;
  bool canceled = false;

  @override
  Future<void> export({
    required Duration start,
    required Duration end,
    required String outputPath,
    required ValueChanged<double> onProgress,
  }) async {
    this.start = start;
    this.end = end;
    this.outputPath = outputPath;
    _onProgress = onProgress;
    await _completion.future;
  }

  void emitProgress(double value) => _onProgress(value);

  void complete() => _completion.complete();

  @override
  Future<void> cancel() async {
    canceled = true;
    if (!_completion.isCompleted) {
      _completion.completeError(const ClipExportException('Clip export canceled.'));
    }
  }
}

void main() {
  group('ClipExportService.defaultSelection', () {
    test('defaults to the previous 30 seconds', () {
      final selection = ClipExportService.defaultSelection(
        position: const Duration(minutes: 1),
        duration: const Duration(minutes: 5),
      );

      expect(selection.start, const Duration(seconds: 30));
      expect(selection.end, const Duration(minutes: 1));
    });

    test('clamps the start to zero and the end to the video duration', () {
      final early = ClipExportService.defaultSelection(
        position: const Duration(seconds: 12),
        duration: const Duration(minutes: 5),
      );
      final pastEnd = ClipExportService.defaultSelection(
        position: const Duration(minutes: 8),
        duration: const Duration(minutes: 5),
      );

      expect(early.start, Duration.zero);
      expect(early.end, const Duration(seconds: 12));
      expect(pastEnd.start, const Duration(minutes: 4, seconds: 30));
      expect(pastEnd.end, const Duration(minutes: 5));
    });
  });

  group('ClipSelection', () {
    test('rejects invalid ranges', () {
      expect(
        () => const ClipSelection(
          start: Duration(seconds: 10),
          end: Duration(seconds: 10),
        ).validate(const Duration(minutes: 1)),
        throwsA(isA<ClipExportException>()),
      );
      expect(
        () => const ClipSelection(
          start: Duration(seconds: 10),
          end: Duration(milliseconds: 10500),
        ).validate(const Duration(minutes: 1)),
        throwsA(isA<ClipExportException>()),
      );
    });
  });

  group('trim window', () {
    test('uses three minutes before and one minute after the selected clip', () {
      final window = ClipExportService.trimWindowForSelection(
        sourceDuration: const Duration(hours: 1),
        selection: const ClipSelection(start: Duration(minutes: 20), end: Duration(minutes: 20, seconds: 30)),
      );

      expect(window.start, const Duration(minutes: 17));
      expect(window.end, const Duration(minutes: 21, seconds: 30));
    });

    test('clamps to the source boundaries near the start and end', () {
      final nearStart = ClipExportService.trimWindowForSelection(
        sourceDuration: const Duration(minutes: 30),
        selection: const ClipSelection(start: Duration(minutes: 1), end: Duration(minutes: 1, seconds: 30)),
      );
      final nearEnd = ClipExportService.trimWindowForSelection(
        sourceDuration: const Duration(minutes: 30),
        selection: const ClipSelection(start: Duration(minutes: 29), end: Duration(minutes: 29, seconds: 30)),
      );

      expect(nearStart.start, Duration.zero);
      expect(nearStart.end, const Duration(minutes: 2, seconds: 30));
      expect(nearEnd.start, const Duration(minutes: 26));
      expect(nearEnd.end, const Duration(minutes: 30));
    });
  });

  group('filename generation', () {
    test('sanitizes metadata and includes the selected time range', () {
      final name = ClipExportService.buildClipFileName(
        _source(title: 'Show: Name/Bad?', subtitle: 'S01E02'),
        const ClipSelection(start: Duration(seconds: 30), end: Duration(minutes: 1)),
      );

      expect(name, 'Show Name Bad - S01E02 - 00m30s-01m00s.mp4');
    });

    test('preserves the source container for Original exports', () {
      final selection = const ClipSelection(start: Duration(seconds: 30), end: Duration(minutes: 1));

      expect(
        ClipExportService.buildClipFileName(
          _source(uri: 'https://example.test/video', container: 'matroska'),
          selection,
          format: ClipExportFormat.source,
        ),
        'Show - S01E02 - 00m30s-01m00s.mkv',
      );
      expect(
        ClipExportService.buildClipFileName(
          _source(uri: 'https://example.test/start.m3u8', isTranscoding: true),
          selection,
          format: ClipExportFormat.source,
        ),
        'Show - S01E02 - 00m30s-01m00s.ts',
      );
    });

    test('uses a neutral extension when the Original container is unknown', () {
      expect(ClipExportService.sourceFileExtension(_source(uri: 'https://example.test/video')), 'media');
    });

    test('builds a sanitized PNG screenshot name from the video timestamp', () {
      expect(
        ClipExportService.buildScreenshotFileName(
          _source(title: 'Show: Name/Bad?', subtitle: 'S01E02'),
          const Duration(minutes: 49, seconds: 40),
        ),
        'Show Name Bad - S01E02 - 49m40s.png',
      );
    });

    test('adds a suffix when a screenshot name already exists', () async {
      final tempDir = await Directory.systemTemp.createTemp('plezy-screenshot-name-test-');
      addTearDown(() => tempDir.delete(recursive: true));
      await File('${tempDir.path}/Show - S01E02 - 02m00s.png').writeAsBytes([1]);

      final output = await ClipExportService.createScreenshotOutputFile(
        _source(),
        const Duration(minutes: 2),
        directoryProvider: () async => tempDir,
      );

      expect(output.path, '${tempDir.path}/Show - S01E02 - 02m00s (2).png');
    });
  });

  group('desktop clip directory resolution', () {
    test('uses HOME/Desktop on macOS and Linux', () {
      final mac = ClipExportService.desktopDirectoryFromEnvironment(
        operatingSystem: 'macos',
        environment: const {'HOME': '/Users/ryan'},
      );
      final linux = ClipExportService.desktopDirectoryFromEnvironment(
        operatingSystem: 'linux',
        environment: const {'HOME': '/home/ryan'},
      );

      expect(mac?.path, '/Users/ryan/Desktop');
      expect(linux?.path, '/home/ryan/Desktop');
    });

    test('uses USERPROFILE Desktop on Windows', () {
      final directory = ClipExportService.desktopDirectoryFromEnvironment(
        operatingSystem: 'windows',
        environment: const {'USERPROFILE': r'C:\Users\ryan'},
      );

      expect(directory?.path, r'C:\Users\ryan\Desktop');
    });

    test('falls back to HOMEDRIVE and HOMEPATH on Windows', () {
      final directory = ClipExportService.desktopDirectoryFromEnvironment(
        operatingSystem: 'windows',
        environment: const {'HOMEDRIVE': r'D:', 'HOMEPATH': r'\Users\ryan'},
      );

      expect(directory?.path, r'D:\Users\ryan\Desktop');
    });

    test('returns null when no desktop home can be resolved', () {
      expect(
        ClipExportService.desktopDirectoryFromEnvironment(operatingSystem: 'linux', environment: const {}),
        isNull,
      );
    });
  });

  group('configured capture directories', () {
    setUp(() {
      resetSharedPreferencesForTest();
      SettingsService.resetForTesting();
    });

    tearDown(() {
      SettingsService.resetForTesting();
      resetSharedPreferencesForTest();
    });

    test('resolves clip and screenshot folders independently', () async {
      final clipDirectory = await Directory.systemTemp.createTemp('plezy-clip-directory-test-');
      final screenshotDirectory = await Directory.systemTemp.createTemp('plezy-screenshot-directory-test-');
      addTearDown(() => clipDirectory.delete(recursive: true));
      addTearDown(() => screenshotDirectory.delete(recursive: true));
      final settings = await SettingsService.getInstance();
      await settings.write(SettingsService.customClipPath, clipDirectory.path);
      await settings.write(SettingsService.customScreenshotPath, screenshotDirectory.path);

      final resolvedClipDirectory = await ClipExportService.clipDirectory();
      final resolvedScreenshotDirectory = await ClipExportService.screenshotDirectory();
      final screenshot = await ClipExportService.createScreenshotOutputFile(_source(), const Duration(minutes: 2));

      expect(resolvedClipDirectory.path, clipDirectory.path);
      expect(resolvedScreenshotDirectory.path, screenshotDirectory.path);
      expect(screenshot.parent.path, screenshotDirectory.path);
    });

    test('validates whether a selected directory is writable', () async {
      final directory = await Directory.systemTemp.createTemp('plezy-capture-write-test-');
      addTearDown(() => directory.delete(recursive: true));
      final blockingFile = File('${directory.path}/not-a-directory');
      await blockingFile.writeAsString('file');

      expect(await ClipExportService.isDirectoryWritable(directory), isTrue);
      expect(await ClipExportService.isDirectoryWritable(Directory(blockingFile.path)), isFalse);
    });
  });

  group('timeline mapping', () {
    test('maps player timeline to a transcoded stream offset', () {
      final mapped = ClipExportService.sourceStartForPosition(
        _source(isTranscoding: true, timelineOffset: const Duration(minutes: 2)),
        const Duration(minutes: 3),
      );

      expect(mapped, const Duration(minutes: 1));
    });

    test('rejects clips that start before the active transcode stream', () {
      expect(
        () => ClipExportService.sourceStartForPosition(
          _source(isTranscoding: true, timelineOffset: const Duration(minutes: 2)),
          const Duration(minutes: 1),
        ),
        throwsA(isA<ClipExportException>()),
      );
    });
  });

  group('MPV cache export', () {
    test('builds a dump-cache command for the selected source range', () {
      final command = MpvClipExportRunner.buildDumpCacheCommand(
        start: const Duration(minutes: 1, milliseconds: 250),
        end: const Duration(minutes: 1, seconds: 31, milliseconds: 500),
        outputPath: '/tmp/clip.mp4',
      );

      expect(command, ['dump-cache', '60.25', '91.5', '/tmp/clip.mp4']);
    });

    test('requires the entire Original selection to be cached contiguously', () {
      const start = Duration(seconds: 30);
      const end = Duration(seconds: 60);

      expect(
        MpvClipExportRunner.cacheRangesCoverSelection(
          ranges: const [BufferRange(start: Duration(seconds: 29), end: Duration(seconds: 61))],
          start: start,
          end: end,
        ),
        isTrue,
      );
      expect(
        MpvClipExportRunner.cacheRangesCoverSelection(
          ranges: const [BufferRange(start: Duration(seconds: 40), end: Duration(seconds: 61))],
          start: start,
          end: end,
        ),
        isFalse,
      );
      expect(
        MpvClipExportRunner.cacheRangesCoverSelection(
          ranges: const [
            BufferRange(start: Duration(seconds: 29), end: Duration(seconds: 45)),
            BufferRange(start: Duration(seconds: 50), end: Duration(seconds: 61)),
          ],
          start: start,
          end: end,
        ),
        isFalse,
      );
    });

    test('reports runner progress and completes after a non-empty file is produced', () async {
      final tempDir = await Directory.systemTemp.createTemp('plezy-clip-export-test-');
      addTearDown(() => tempDir.delete(recursive: true));
      final runner = _FakeClipExportRunner();
      final service = ClipExportService(exportRunner: runner, clipsDirectoryProvider: () async => tempDir);
      addTearDown(service.dispose);

      final export = service.exportClip(
        source: _source(),
        selection: const ClipSelection(start: Duration(seconds: 30), end: Duration(seconds: 60)),
      );
      await pumpEventQueue();

      runner.emitProgress(0.5);
      expect(service.state.value.stage, ClipExportStage.running);
      expect(service.state.value.progress, closeTo(0.5, 0.0001));

      await File(runner.outputPath).writeAsBytes([1, 2, 3]);
      runner.complete();

      await export;
      expect(service.state.value.stage, ClipExportStage.completed);
      expect(service.state.value.progress, 1);
      expect(runner.start, const Duration(seconds: 30));
      expect(runner.end, const Duration(seconds: 60));
    });

    test('forwards cancellation to the active runner', () async {
      final tempDir = await Directory.systemTemp.createTemp('plezy-clip-cancel-test-');
      addTearDown(() => tempDir.delete(recursive: true));
      final runner = _FakeClipExportRunner();
      final service = ClipExportService(exportRunner: runner, clipsDirectoryProvider: () async => tempDir);
      addTearDown(service.dispose);

      final export = service.exportClip(
        source: _source(),
        selection: const ClipSelection(start: Duration(seconds: 30), end: Duration(seconds: 60)),
      );
      await pumpEventQueue();

      final cancellation = expectLater(export, throwsA(isA<ClipExportException>()));
      await service.cancelActiveExport();

      await cancellation;
      expect(runner.canceled, isTrue);
      expect(service.state.value.stage, ClipExportStage.canceled);
    });

    test('dispose cancels an active export without updating disposed state', () async {
      final tempDir = await Directory.systemTemp.createTemp('plezy-clip-dispose-test-');
      addTearDown(() => tempDir.delete(recursive: true));
      final runner = _FakeClipExportRunner();
      final service = ClipExportService(exportRunner: runner, clipsDirectoryProvider: () async => tempDir);

      final export = service.exportClip(
        source: _source(),
        selection: const ClipSelection(start: Duration(seconds: 30), end: Duration(seconds: 60)),
      );
      await pumpEventQueue();

      service.dispose();

      await expectLater(export, throwsA(isA<ClipExportException>()));
      expect(runner.canceled, isTrue);
    });

    test('reports a failed Original export when no preview player is available', () async {
      final tempDir = await Directory.systemTemp.createTemp('plezy-clip-no-player-test-');
      addTearDown(() => tempDir.delete(recursive: true));
      final service = ClipExportService(clipsDirectoryProvider: () async => tempDir);
      addTearDown(service.dispose);

      await expectLater(
        service.exportClip(
          source: _source(),
          selection: const ClipSelection(start: Duration(seconds: 30), end: Duration(seconds: 60)),
          format: ClipExportFormat.source,
        ),
        throwsA(isA<ClipExportException>()),
      );

      expect(service.state.value.stage, ClipExportStage.failed);
    });
  });

  group('desktop encoding formats', () {
    test('defaults macOS and Windows to HEVC SDR and offers Original everywhere', () {
      expect(ClipExportService.formatsForOperatingSystem('macos'), [
        ClipExportFormat.hevcSdr,
        ClipExportFormat.h264Sdr,
        ClipExportFormat.source,
      ]);
      expect(ClipExportService.formatsForOperatingSystem('windows'), [
        ClipExportFormat.hevcSdr,
        ClipExportFormat.h264Sdr,
        ClipExportFormat.source,
      ]);
      expect(ClipExportService.formatsForOperatingSystem('linux'), [ClipExportFormat.source]);
      expect(ClipExportService.defaultFormatForOperatingSystem('macos'), ClipExportFormat.hevcSdr);
      expect(ClipExportService.defaultFormatForOperatingSystem('linux'), ClipExportFormat.source);
    });

    test('offers HEVC HDR only for direct HDR10 or HLG-compatible sources', () {
      for (final criteria in [_pqCriteria, _hlgCriteria, _dolbyVisionHdr10Criteria]) {
        expect(
          ClipExportService.formatsForOperatingSystem('macos', source: _source(displayCriteria: criteria)),
          contains(ClipExportFormat.hevcHdr),
        );
      }

      expect(
        ClipExportService.formatsForOperatingSystem(
          'windows',
          source: _source(isTranscoding: true, displayCriteria: _pqCriteria),
        ),
        isNot(contains(ClipExportFormat.hevcHdr)),
      );
      expect(
        ClipExportService.formatsForOperatingSystem(
          'macos',
          source: _source(displayCriteria: _dolbyVisionOnlyCriteria),
        ),
        isNot(contains(ClipExportFormat.hevcHdr)),
      );
    });

    test('uses bundled VideoToolbox encoders and explicit SDR output on macOS', () {
      final source = _source(displayCriteria: _sdrCriteria);
      final h264 = _encodingOptions(ClipExportFormat.h264Sdr, source: source);
      final hevc = _encodingOptions(ClipExportFormat.hevcSdr, source: source);

      expect(h264['ovc'], 'h264_videotoolbox');
      expect(h264['ovcopts'], isNot(contains('codec_tag=')));
      expect(hevc['ovc'], 'hevc_videotoolbox');
      expect(hevc['ovcopts'], contains('codec_tag=828601960'));
      expect(hevc['ovcopts'], contains('profile=main'));
      expect(hevc['ovcopts'], contains('color_primaries=1'));
      expect(hevc['ovcopts'], contains('pixel_format=yuv420p'));
      expect(hevc['vf'], contains('fmt=yuv420p'));
      expect(hevc['vf'], isNot(startsWith('gpu=')));
      expect(h264['oac'], 'aac_at');
      expect(h264['start'], '30');
      expect(h264['end'], '60');
    });

    test('tone-maps HDR sources to SDR through the bundled mpv GPU filter', () {
      final options = _encodingOptions(ClipExportFormat.hevcSdr, source: _source(displayCriteria: _pqCriteria));

      expect(options['vf'], startsWith('gpu=api=vulkan,'));
      expect(options['vf'], contains('fmt=yuv420p'));
      expect(options['target-prim'], 'bt.709');
      expect(options['target-trc'], 'bt.1886');
      expect(options['target-peak'], '203');
      expect(options['tone-mapping'], 'mobius');
      expect(options['hwdec'], 'no');
    });

    test('uses color conversion for SDR export when source metadata is unknown', () {
      final options = _encodingOptions(ClipExportFormat.h264Sdr);

      expect(options['vf'], startsWith('gpu=api=vulkan,'));
      expect(options['target-prim'], 'bt.709');
      expect(options['target-trc'], 'bt.1886');
    });

    test('uses Main10 VideoToolbox with PQ or HLG signaling for HEVC HDR', () {
      final pq = _encodingOptions(ClipExportFormat.hevcHdr, source: _source(displayCriteria: _pqCriteria));
      final hlg = _encodingOptions(ClipExportFormat.hevcHdr, source: _source(displayCriteria: _hlgCriteria));

      expect(pq['ovc'], 'hevc_videotoolbox');
      expect(pq['ovcopts'], contains('profile=main10'));
      expect(pq['ovcopts'], contains('pixel_format=p010le'));
      expect(pq['ovcopts'], contains('color_trc=16'));
      expect(pq['vf'], contains('gamma=pq'));
      expect(hlg['ovcopts'], contains('color_trc=18'));
      expect(hlg['vf'], contains('gamma=hlg'));
    });

    test('uses bundled software encoders on Windows', () {
      final h264 = _encodingOptions(ClipExportFormat.h264Sdr, operatingSystem: 'windows');
      final hevc = _encodingOptions(ClipExportFormat.hevcSdr, operatingSystem: 'windows');

      expect(h264['ovc'], 'libx264');
      expect(h264['ovcopts'], isNot(contains('codec_tag=')));
      expect(hevc['ovc'], 'libx265');
      expect(hevc['ovcopts'], contains('codec_tag=828601960'));
      expect(h264['oac'], 'aac');
    });

    test('uses 10-bit libx265 for HDR on Windows', () {
      final options = _encodingOptions(
        ClipExportFormat.hevcHdr,
        operatingSystem: 'windows',
        source: _source(displayCriteria: _pqCriteria),
      );

      expect(options['ovc'], 'libx265');
      expect(options['ovcopts'], contains('profile=main10'));
      expect(options['ovcopts'], contains('pixel_format=yuv420p10le'));
      expect(options['ovcopts'], contains('color_primaries=9'));
    });

    test('rejects HDR encoding for SDR, transcoded, and Dolby Vision-only sources', () {
      for (final source in [
        _source(),
        _source(isTranscoding: true, displayCriteria: _pqCriteria),
        _source(displayCriteria: _dolbyVisionOnlyCriteria),
      ]) {
        expect(() => _encodingOptions(ClipExportFormat.hevcHdr, source: source), throwsA(isA<ClipExportException>()));
      }
    });
  });
}
