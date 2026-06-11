import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_version.dart';
import 'package:plezy/models/transcode_quality_preset.dart';
import 'package:plezy/services/playback_context.dart';
import 'package:plezy/services/playback_initialization_types.dart';
import 'package:plezy/services/playback_session.dart';

PlaybackContext _context(PlaybackInitializationResult result) {
  return PlaybackContext(
    metadata: MediaItem(id: 'item-1', backend: MediaBackend.plex, kind: MediaKind.movie, serverId: 'srv'),
    result: result,
    sourceKind: result.usesLocalMedia ? PlaybackSourceKind.localFile : PlaybackSourceKind.remoteDirect,
    reportingMode: PlaybackReportingMode.online,
    streamHeaders: const {'X-Test': 'token'},
  );
}

void main() {
  group('PlaybackSession.fromContext', () {
    test('keeps the requested preset when no fallback occurred', () {
      final session = PlaybackSession.fromContext(
        _context(PlaybackInitializationResult(availableVersions: const [], videoUrl: 'u')),
        requestedQualityPreset: TranscodeQualityPreset.p1080_8mbps,
      );
      expect(session.qualityPreset, TranscodeQualityPreset.p1080_8mbps);
    });

    test('falls back to original when the backend rejected the preset', () {
      final session = PlaybackSession.fromContext(
        _context(
          PlaybackInitializationResult(
            availableVersions: const [],
            videoUrl: 'u',
            fallbackReason: TranscodeFallbackReason.values.first,
          ),
        ),
        requestedQualityPreset: TranscodeQualityPreset.p1080_8mbps,
      );
      expect(session.qualityPreset, TranscodeQualityPreset.original);
    });

    test('an original-quality request ignores the fallback reason', () {
      final session = PlaybackSession.fromContext(
        _context(
          PlaybackInitializationResult(
            availableVersions: const [],
            videoUrl: 'u',
            fallbackReason: TranscodeFallbackReason.values.first,
          ),
        ),
        requestedQualityPreset: TranscodeQualityPreset.original,
      );
      expect(session.qualityPreset, TranscodeQualityPreset.original);
    });

    test('refines the media source id from the clamped version index', () {
      final versions = [MediaVersion(id: 'v0'), MediaVersion(id: 'v1')];
      final session = PlaybackSession.fromContext(
        _context(PlaybackInitializationResult(availableVersions: versions, videoUrl: 'u', selectedMediaIndex: 1)),
        requestedQualityPreset: TranscodeQualityPreset.original,
        requestedMediaSourceId: 'requested',
      );
      expect(session.mediaSourceId, 'v1');
      expect(session.mediaIndex, 1);
    });

    test('keeps the requested source id when the index is out of range', () {
      final session = PlaybackSession.fromContext(
        _context(PlaybackInitializationResult(availableVersions: const [], videoUrl: 'u', selectedMediaIndex: 2)),
        requestedQualityPreset: TranscodeQualityPreset.original,
        requestedMediaSourceId: 'requested',
      );
      expect(session.mediaSourceId, 'requested');
    });
  });

  test('forwarding getters mirror the resolver output', () {
    final result = PlaybackInitializationResult(
      availableVersions: [MediaVersion(id: 'v0')],
      videoUrl: 'u',
      isTranscoding: true,
      playSessionId: 'psid',
      playMethod: 'Transcode',
      activeAudioStreamId: 7,
    );
    final session = PlaybackSession.fromContext(
      _context(result),
      requestedQualityPreset: TranscodeQualityPreset.original,
    );

    expect(session.isTranscoding, isTrue);
    expect(session.isOffline, isFalse);
    expect(session.playSessionId, 'psid');
    expect(session.playMethod, 'Transcode');
    expect(session.audioStreamId, 7);
    expect(session.availableVersions, hasLength(1));
    expect(session.streamHeaders, containsPair('X-Test', 'token'));
    expect(session.metadata.id, 'item-1');
  });
}
