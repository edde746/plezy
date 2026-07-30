import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/services/subtitle_preference.dart';

void main() {
  group('SubtitleIntent.fromTrack', () {
    test('returns null for null, off, and metadata-less tracks', () {
      expect(SubtitleIntent.fromTrack(null), isNull);
      expect(SubtitleIntent.fromTrack(SubtitleTrack.off), isNull);
      expect(SubtitleIntent.fromTrack(const SubtitleTrack(id: '3')), isNull);
    });

    test('captures effective forced-ness from the title (#1716)', () {
      final intent = SubtitleIntent.fromTrack(
        const SubtitleTrack(id: 'source:8', title: 'FR Forced [ASS]', language: 'fre', codec: 'ass'),
      );
      expect(intent, isNotNull);
      expect(intent!.forced, isTrue);
      expect(intent.language, 'fre');
    });

    test('captures effective forced-ness from the flag', () {
      final intent = SubtitleIntent.fromTrack(
        const SubtitleTrack(id: '4', language: 'fre', isForced: true),
      );
      expect(intent!.forced, isTrue);
    });

    test('full track produces a non-forced intent', () {
      final intent = SubtitleIntent.fromTrack(
        const SubtitleTrack(id: '4', title: 'French', language: 'fre', codec: 'srt'),
      );
      expect(intent!.forced, isFalse);
    });
  });

  group('SubtitlePreference.trackOrNull', () {
    test('maps null, off, and real tracks', () {
      expect(SubtitlePreference.trackOrNull(null), isNull);
      expect(SubtitlePreference.trackOrNull(SubtitleTrack.off), const SubtitlePreference.off());
      const track = SubtitleTrack(id: 'source:5', language: 'eng');
      expect(SubtitlePreference.trackOrNull(track), const SubtitlePreference.track(track));
    });
  });

  group('SubtitlePreference.demoteToIntent', () {
    test('off and intents pass through, null stays null', () {
      const off = SubtitlePreference.off();
      expect(SubtitlePreference.demoteToIntent(off), off);
      const intent = SubtitlePreference.intent(SubtitleIntent(language: 'fre', forced: true));
      expect(SubtitlePreference.demoteToIntent(intent), intent);
      expect(SubtitlePreference.demoteToIntent(null), isNull);
    });

    test('track references become intents with effective forced-ness', () {
      final demoted = SubtitlePreference.demoteToIntent(
        const SubtitlePreference.track(SubtitleTrack(id: 'source:8', title: 'FR Forced', language: 'fre', codec: 'ass')),
      );
      expect(
        demoted,
        const SubtitlePreference.intent(
          SubtitleIntent(language: 'fre', forced: true, title: 'FR Forced', codec: 'ass'),
        ),
      );
    });

    test('sidecar uri references also lose their identity', () {
      final demoted = SubtitlePreference.demoteToIntent(
        SubtitlePreference.track(
          SubtitleTrack.uri('https://server/library/streams/9.srt', language: 'eng', codec: 'srt'),
        ),
      );
      expect(demoted, isA<SubtitleIntentPreference>());
      expect((demoted! as SubtitleIntentPreference).intent.isExternal, isTrue);
    });

    test('metadata-less track references demote to null', () {
      expect(
        SubtitlePreference.demoteToIntent(const SubtitlePreference.track(SubtitleTrack(id: '2'))),
        isNull,
      );
    });
  });
}
