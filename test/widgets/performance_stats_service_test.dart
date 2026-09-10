import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/widgets/video_controls/widgets/performance_overlay/performance_stats.dart';
import 'package:plezy/widgets/video_controls/widgets/performance_overlay/performance_stats_service.dart';

/// Player fake that answers mpv property queries from a fixed map.
class _PropertyPlayer implements Player {
  _PropertyPlayer(this.properties);

  final Map<String, String> properties;

  @override
  final PlayerStreams streams = const PlayerStreams(
    playing: Stream.empty(),
    completed: Stream.empty(),
    buffering: Stream.empty(),
    position: Stream.empty(),
    duration: Stream.empty(),
    seekable: Stream.empty(),
    buffer: Stream.empty(),
    volume: Stream.empty(),
    rate: Stream.empty(),
    tracks: Stream.empty(),
    track: Stream.empty(),
    log: Stream.empty(),
    error: Stream.empty(),
    audioDevice: Stream.empty(),
    audioDevices: Stream.empty(),
    bufferRanges: Stream.empty(),
    playbackRestart: Stream.empty(),
    fileStarted: Stream.empty(),
    fileLoaded: Stream.empty(),
    fileLoadFailed: Stream.empty(),
    primaryMediaReady: Stream.empty(),
    backendSwitched: Stream.empty(),
  );

  @override
  bool get providesNativeStats => false;

  @override
  Future<String?> getProperty(String name) async => properties[name];

  @override
  Future<String> runtimePlayerType() async => 'mpv';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Player fake that reports native (Android ExoPlayer) stats.
class _NativeStatsPlayer extends _PropertyPlayer {
  _NativeStatsPlayer(this.stats) : super(const {});

  final Map<String, dynamic> stats;

  @override
  bool get providesNativeStats => true;

  @override
  Future<Map<String, dynamic>> getStats() async => stats;

  @override
  Future<String> runtimePlayerType() async => 'exoplayer';
}

Future<PerformanceStats> _firstStats(_PropertyPlayer player) async {
  final service = PerformanceStatsService(player);
  try {
    final first = service.statsStream.first;
    service.startPolling();
    return await first;
  } finally {
    service.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PerformanceStatsService audio display', () {
    test('spdif passthrough reports the source track, not the IEC carrier (#1300)', () async {
      // mpv's audio-params during E-AC-3 bitstreaming: the 192 kHz "stereo"
      // IEC 61937 carrier. The overlay must show the 48 kHz 5.1 source track.
      final stats = await _firstStats(
        _PropertyPlayer({
          'audio-codec-name': 'eac3',
          'audio-params/format': 'spdif-eac3',
          'audio-params/samplerate': '192000',
          'audio-params/hr-channels': 'stereo',
          'current-tracks/audio/demux-samplerate': '48000',
          'current-tracks/audio/demux-channel-count': '6',
        }),
      );

      expect(stats.audioSamplerate, 48000);
      expect(stats.audioChannels, '5.1');
      expect(stats.audioPassthrough, isTrue);
      expect(stats.audioPassthroughFormatted, 'E-AC3');
    });

    test('locally decoded audio keeps mpv audio-params verbatim', () async {
      final stats = await _firstStats(
        _PropertyPlayer({
          'audio-codec-name': 'eac3',
          'audio-params/format': 'floatp',
          'audio-params/samplerate': '48000',
          'audio-params/hr-channels': '5.1',
          'current-tracks/audio/demux-samplerate': '48000',
          'current-tracks/audio/demux-channel-count': '6',
        }),
      );

      expect(stats.audioSamplerate, 48000);
      expect(stats.audioChannels, '5.1');
      expect(stats.audioPassthrough, isFalse);
    });

    test('passthrough with unavailable track metadata degrades to N/A, never the carrier', () async {
      final stats = await _firstStats(
        _PropertyPlayer({
          'audio-params/format': 'spdif-dts-hd',
          'audio-params/samplerate': '192000',
          'audio-params/hr-channels': 'stereo',
        }),
      );

      expect(stats.audioSamplerate, isNull);
      expect(stats.audioChannels, isNull);
      expect(stats.audioPassthrough, isTrue);
      expect(stats.audioPassthroughFormatted, 'DTS-HD');
    });
  });

  group('PerformanceStatsService ExoPlayer codec display (#2063)', () {
    test('falls back to the sample MIME type when the container has no codecs string', () async {
      // Matroska: Format.codecs is null; only the MIME types identify the
      // streams.
      final stats = await _firstStats(
        _NativeStatsPlayer({
          'playerType': 'exoplayer',
          'videoCodec': null,
          'videoMimeType': 'video/hevc',
          'audioCodec': null,
          'audioMimeType': 'audio/eac3',
          'audioSampleRate': 48000,
          'audioChannels': 6,
        }),
      );

      expect(stats.videoCodec, 'HEVC');
      expect(stats.audioCodec, 'E-AC3');
      expect(stats.audioChannels, '5.1');
    });

    test('an explicit codecs string wins over the MIME type', () async {
      final stats = await _firstStats(
        _NativeStatsPlayer({
          'playerType': 'exoplayer',
          'videoCodec': 'hvc1.2.4.L153.B0',
          'videoMimeType': 'video/hevc',
          'audioCodec': 'mp4a.40.2',
          'audioMimeType': 'audio/mp4a-latm',
        }),
      );

      expect(stats.videoCodec, 'HEVC');
      expect(stats.audioCodec, 'AAC');
    });

    test('measured audio bitrate from the native side is surfaced', () async {
      final stats = await _firstStats(
        _NativeStatsPlayer({'playerType': 'exoplayer', 'audioMimeType': 'audio/vnd.dts', 'audioBitrate': 1509000}),
      );

      expect(stats.audioCodec, 'DTS');
      expect(stats.hasValidAudioBitrate, isTrue);
      expect(stats.audioBitrateFormatted, '1509 kbps');
    });
  });

  group('PerformanceStatsService cache reporting', () {
    // mpv deleted `cache-used` with its stream cache, so the forward byte
    // count now comes out of the `demuxer-cache-state` JSON blob. Both
    // platform paths keep their own property list, so both are asserted.
    const cacheState = '{"fw-bytes":12582912,"total-bytes":20971520,"eof":false}';

    test('Android native stats read fw-bytes out of demuxer-cache-state', () async {
      final stats = await _firstStats(
        _NativeStatsPlayer({'playerType': 'mpv', 'demuxer-cache-state': cacheState, 'demuxer-max-bytes': '20971520'}),
      );

      expect(stats.cacheUsed, 12582912);
      expect(stats.cacheUsedFormatted, '12.0 MB');
    });

    test('desktop property path reads the same blob', () async {
      final stats = await _firstStats(_PropertyPlayer({'demuxer-cache-state': cacheState}));

      expect(stats.cacheUsed, 12582912);
      expect(stats.cacheUsedFormatted, '12.0 MB');
    });

    test('the verbatim mpv serialisation parses, nested arrays and all', () async {
      // Captured from the pinned libmpv (mpv 0.41.0) with MPV_FORMAT_STRING:
      // the blob is not a flat map, so the parser must really decode JSON.
      const verbatim =
          '{"cache-end":5.960000,"reader-pts":0.360000,"cache-duration":5.600000,"eof":true,'
          '"underrun":false,"idle":true,"total-bytes":376864,"fw-bytes":347648,'
          '"raw-input-rate":2481023,"debug-low-level-seeks":0,"debug-byte-level-seeks":1,'
          '"debug-ts-last":5.990748,"ts-per-stream":[{"type":"video","cache-duration":5.600000,'
          '"reader-pts":0.360000,"cache-end":5.960000},{"type":"audio","cache-duration":5.804989,'
          '"reader-pts":0.185760,"cache-end":5.990748}],"bof-cached":true,"eof-cached":true,'
          '"seekable-ranges":[{"start":-0.023220,"end":5.990748}]}';

      final stats = await _firstStats(_PropertyPlayer({'demuxer-cache-state': verbatim}));

      expect(stats.cacheUsed, 347648);
    });

    test('an unavailable demuxer-cache-state degrades to N/A', () async {
      final stats = await _firstStats(_PropertyPlayer(const {}));

      expect(stats.cacheUsed, isNull);
      expect(stats.cacheUsedFormatted, 'N/A');
    });

    test('malformed or unexpected demuxer-cache-state degrades to N/A without throwing', () async {
      for (final blob in ['{"fw-bytes":', 'not json at all', '[]', '{"total-bytes":20971520}', '{"fw-bytes":"lots"}']) {
        final stats = await _firstStats(_PropertyPlayer({'demuxer-cache-state': blob}));

        expect(stats.cacheUsed, isNull, reason: blob);
        expect(stats.cacheUsedFormatted, 'N/A', reason: blob);
      }
    });
  });
}
