import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/utils/subtitle_forced_semantics.dart';

MediaSubtitleTrack _row({bool forced = false, String? title, String? displayTitle}) =>
    MediaSubtitleTrack(id: 1, selected: false, forced: forced, title: title, displayTitle: displayTitle);

void main() {
  group('MediaSubtitleTrack.effectiveForced', () {
    test('flag alone qualifies', () {
      expect(_row(forced: true).effectiveForced, isTrue);
    });

    test('title alone qualifies', () {
      expect(_row(title: 'FR Forced').effectiveForced, isTrue);
    });

    test('displayTitle alone qualifies', () {
      expect(_row(displayTitle: 'Français (Forced SRT)').effectiveForced, isTrue);
    });

    test('neither flag nor title qualifies', () {
      expect(_row(title: 'French', displayTitle: 'Français (SRT)').effectiveForced, isFalse);
      expect(_row().effectiveForced, isFalse);
    });
  });

  group('SubtitleTrack.effectiveForced', () {
    test('flag alone qualifies', () {
      expect(const SubtitleTrack(id: '1', isForced: true).effectiveForced, isTrue);
    });

    test('title alone qualifies', () {
      expect(const SubtitleTrack(id: '1', title: 'FR Forced [ASS]').effectiveForced, isTrue);
    });

    test('plain title does not qualify', () {
      expect(const SubtitleTrack(id: '1', title: 'French').effectiveForced, isFalse);
      expect(const SubtitleTrack(id: '1').effectiveForced, isFalse);
    });
  });
}
