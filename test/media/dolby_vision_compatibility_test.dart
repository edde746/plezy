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
    expect(shouldRequestCompatibleDolbyVisionRendition(requested: true, source: hdr10), isFalse);
    expect(shouldRequestCompatibleDolbyVisionRendition(requested: true, source: null), isFalse);
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
