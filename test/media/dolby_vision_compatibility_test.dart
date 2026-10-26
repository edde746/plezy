import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/dolby_vision_compatibility.dart';
import 'package:plezy/media/media_display_criteria.dart';
import 'package:plezy/mpv/models.dart';

void main() {
  test('compatibility rendition routing requires an identified DV profile and an adapter request', () {
    const dolbyVision = MediaDisplayCriteria(doviProfile: 7, doviCompatibilityId: 6);
    const hdr10 = MediaDisplayCriteria(transfer: 'smpte2084', primaries: 'bt2020');

    expect(shouldRequestCompatibleDolbyVisionRendition(requested: false, source: dolbyVision), isFalse);
    expect(shouldRequestCompatibleDolbyVisionRendition(requested: true, source: dolbyVision), isTrue);
    expect(
      shouldRequestCompatibleDolbyVisionRendition(
        requested: true,
        source: dolbyVision,
        supportedNativeProfiles: const {7},
      ),
      isFalse,
    );
    expect(
      shouldRequestCompatibleDolbyVisionRendition(
        requested: true,
        source: dolbyVision,
        allowExperimentalProfile7: true,
      ),
      isFalse,
    );
    expect(
      shouldRequestCompatibleDolbyVisionRendition(
        requested: true,
        source: dolbyVision,
        supportedNativeProfiles: const {5},
      ),
      isTrue,
    );
    expect(shouldRequestCompatibleDolbyVisionRendition(requested: true, source: hdr10), isFalse);
    expect(shouldRequestCompatibleDolbyVisionRendition(requested: true, source: null), isFalse);
  });

  test('server SDR routes are profile- and backend-specific', () {
    const profile5 = MediaDisplayCriteria(doviProfile: 5, doviBaseLayerPresent: false);
    const profile7Hdr10 = MediaDisplayCriteria(doviProfile: 7, doviCompatibilityId: 6, doviBaseLayerPresent: true);
    const profile7InferredHdr10 = MediaDisplayCriteria(doviProfile: 7, doviCompatibilityId: 6);
    const profile8Hdr10 = MediaDisplayCriteria(doviProfile: 8, doviCompatibilityId: 1, doviBaseLayerPresent: true);
    const profile8Hlg = MediaDisplayCriteria(doviProfile: 8, doviCompatibilityId: 4, doviBaseLayerPresent: true);
    const unknownProfile = MediaDisplayCriteria(dolbyVisionPresent: true);

    expect(serverHasDolbyVisionSdrRoute(backend: DolbyVisionSdrBackend.jellyfin, source: profile5), isTrue);
    expect(serverHasDolbyVisionSdrRoute(backend: DolbyVisionSdrBackend.jellyfin, source: profile8Hlg), isTrue);
    expect(serverHasDolbyVisionSdrRoute(backend: DolbyVisionSdrBackend.jellyfin, source: profile7Hdr10), isTrue);
    expect(
      serverHasDolbyVisionSdrRoute(backend: DolbyVisionSdrBackend.jellyfin, source: profile7InferredHdr10),
      isTrue,
    );

    expect(serverHasDolbyVisionSdrRoute(backend: DolbyVisionSdrBackend.plex, source: profile5), isFalse);
    expect(serverHasDolbyVisionSdrRoute(backend: DolbyVisionSdrBackend.plex, source: profile7Hdr10), isTrue);
    expect(serverHasDolbyVisionSdrRoute(backend: DolbyVisionSdrBackend.plex, source: profile8Hdr10), isTrue);
    expect(serverHasDolbyVisionSdrRoute(backend: DolbyVisionSdrBackend.plex, source: profile8Hlg), isFalse);

    expect(serverHasDolbyVisionSdrRoute(backend: DolbyVisionSdrBackend.emby, source: profile5), isFalse);
    expect(serverHasDolbyVisionSdrRoute(backend: DolbyVisionSdrBackend.emby, source: profile7Hdr10), isTrue);
    expect(serverHasDolbyVisionSdrRoute(backend: DolbyVisionSdrBackend.emby, source: profile8Hdr10), isTrue);
    expect(serverHasDolbyVisionSdrRoute(backend: DolbyVisionSdrBackend.emby, source: unknownProfile), isFalse);
    expect(
      serverHasDolbyVisionSdrRoute(
        backend: DolbyVisionSdrBackend.plex,
        source: const MediaDisplayCriteria(doviProfile: 7, doviCompatibilityId: 6, doviBaseLayerPresent: false),
      ),
      isFalse,
    );
  });

  test('compatibility HLS output must explicitly declare SDR for every video variant', () {
    const sdr = '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=5000000,VIDEO-RANGE=SDR,CODECS="avc1.640028,mp4a.40.2"
stream.m3u8
''';
    const mixed = '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=5000000,VIDEO-RANGE=SDR,CODECS="avc1.640028"
sdr.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=9000000,VIDEO-RANGE=PQ,CODECS="hvc1.2.4.L150"
hdr.m3u8
''';

    expect(hlsMasterDeclaresSdrVideoOutput(sdr), isTrue);
    expect(hlsMasterDeclaresSdrVideoOutput(mixed), isFalse);
    expect(hlsMasterDeclaresSdrVideoOutput('#EXTM3U\n#EXTINF:4.0,\nsegment.ts'), isFalse);
    expect(hlsMasterDeclaresSdrVideoOutput('#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=5000000\nstream.m3u8'), isFalse);
  });

  test('automatic fallback retries native/local Dolby Vision failures once', () {
    const dolbyVision = MediaDisplayCriteria(doviProfile: 7, doviCompatibilityId: 6);

    expect(
      shouldAttemptAutomaticDolbyVisionCompatibilityFallback(
        source: dolbyVision,
        isOnline: true,
        isLive: false,
        serverSupportsTranscoding: true,
        alreadyTranscoding: false,
        alreadyAttempted: false,
        fatalHttpStatuses: const {},
        failureCause: PlayerError.streamInitFailed,
      ),
      isTrue,
    );
    expect(
      shouldAttemptAutomaticDolbyVisionCompatibilityFallback(
        source: dolbyVision,
        isOnline: true,
        isLive: false,
        serverSupportsTranscoding: true,
        alreadyTranscoding: false,
        alreadyAttempted: false,
        fatalHttpStatuses: const {},
        failureCause: PlayerError.openTimedOut,
      ),
      isTrue,
    );
  });

  test('automatic fallback declines unrelated errors and ineligible playback', () {
    const dolbyVision = MediaDisplayCriteria(doviProfile: 5);
    const hdr10 = MediaDisplayCriteria(transfer: 'smpte2084', primaries: 'bt2020');
    final base = <String, Object?>{
      'source': dolbyVision,
      'isOnline': true,
      'isLive': false,
      'serverSupportsTranscoding': true,
      'alreadyTranscoding': false,
      'alreadyAttempted': false,
      'fatalHttpStatuses': const <int>{},
      'failureCause': PlayerError.streamInitFailed,
    };

    bool eligible(Map<String, Object?> overrides) {
      final values = {...base, ...overrides};
      return shouldAttemptAutomaticDolbyVisionCompatibilityFallback(
        source: values['source'] as MediaDisplayCriteria?,
        isOnline: values['isOnline']! as bool,
        isLive: values['isLive']! as bool,
        serverSupportsTranscoding: values['serverSupportsTranscoding']! as bool,
        alreadyTranscoding: values['alreadyTranscoding']! as bool,
        alreadyAttempted: values['alreadyAttempted']! as bool,
        fatalHttpStatuses: values['fatalHttpStatuses']! as Set<int>,
        failureCause: values['failureCause'] as String?,
      );
    }

    expect(eligible({'source': hdr10}), isFalse);
    expect(eligible({'source': null}), isFalse);
    expect(eligible({'isOnline': false}), isFalse);
    expect(eligible({'isLive': true}), isFalse);
    expect(eligible({'serverSupportsTranscoding': false}), isFalse);
    expect(eligible({'alreadyTranscoding': true}), isFalse);
    expect(eligible({'alreadyAttempted': true}), isFalse);
    expect(
      eligible({
        'fatalHttpStatuses': <int>{403},
      }),
      isFalse,
    );
    expect(eligible({'failureCause': PlayerError.audioOutputFailed}), isFalse);
    expect(eligible({'failureCause': PlayerError.serverHttp404}), isFalse);
  });
}
