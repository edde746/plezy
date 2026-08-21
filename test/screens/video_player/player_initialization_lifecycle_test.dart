import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/focusable_button.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/services/playback_subtitle_resolver.dart';
import 'package:plezy/screens/video_player_screen.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/subtitle_preference.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/media_items.dart';
import '../../test_helpers/mock_player_channels.dart';
import '../../test_helpers/prefs.dart';
import '../../test_helpers/pump.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  test('in-place reload preserves the current playback intent', () {
    expect(
      shouldAutoStartReloadedMedia(wasPlayingBeforeReload: false, watchTogetherOwnsStart: false, startPaused: false),
      isFalse,
    );
    expect(
      shouldAutoStartReloadedMedia(wasPlayingBeforeReload: true, watchTogetherOwnsStart: false, startPaused: false),
      isTrue,
    );
    expect(
      shouldAutoStartReloadedMedia(wasPlayingBeforeReload: true, watchTogetherOwnsStart: true, startPaused: false),
      isFalse,
    );
    expect(
      shouldAutoStartReloadedMedia(wasPlayingBeforeReload: true, watchTogetherOwnsStart: false, startPaused: true),
      isFalse,
    );
  });

  test('item-change subtitle preference carries committed semantics without item identity', () {
    const committed = SubtitleTrack(
      id: 'source:4',
      title: 'French - SRT',
      language: 'fra',
      codec: 'srt',
      isForced: true,
      isExternal: true,
      uri: 'https://example.test/old-episode/subtitle.srt',
    );

    final result = subtitlePreferenceForItemChange(
      hasCommittedSelection: true,
      committedTrack: committed,
      nativeTrack: SubtitleTrack.off,
      sessionPreference: null,
    );

    expect(result, isA<SubtitleIntentPreference>());
    final intent = (result! as SubtitleIntentPreference).intent;
    expect(intent.title, committed.title);
    expect(intent.language, committed.language);
    expect(intent.codec, committed.codec);
    expect(intent.forced, isTrue);
    expect(intent.isExternal, isTrue);
  });

  test('session subtitle intent wins over the committed outcome at an item boundary', () {
    const sessionPreference = SubtitlePreference.intent(
      SubtitleIntent(language: 'swe', forced: false, title: 'Swedish', codec: 'srt'),
    );

    final result = subtitlePreferenceForItemChange(
      hasCommittedSelection: true,
      committedTrack: const SubtitleTrack(id: 'source:4', language: 'eng', title: 'English', codec: 'srt'),
      nativeTrack: const SubtitleTrack(id: '2', language: 'eng', title: 'English', codec: 'srt'),
      sessionPreference: sessionPreference,
    );

    expect(result, sessionPreference);
  });

  test('session subtitle off stays off at an item boundary', () {
    expect(
      subtitlePreferenceForItemChange(
        hasCommittedSelection: true,
        committedTrack: const SubtitleTrack(id: 'source:4', language: 'eng'),
        nativeTrack: const SubtitleTrack(id: '2', language: 'eng'),
        sessionPreference: const SubtitlePreference.off(),
      ),
      const SubtitlePreference.off(),
    );
  });

  test('semantics-free session subtitle preference falls back to the committed flow', () {
    final result = subtitlePreferenceForItemChange(
      hasCommittedSelection: true,
      committedTrack: const SubtitleTrack(id: 'source:4', language: 'eng', title: 'English', codec: 'srt'),
      nativeTrack: SubtitleTrack.off,
      sessionPreference: const SubtitlePreference.track(SubtitleTrack(id: 'source:9')),
    );

    expect(result, isA<SubtitleIntentPreference>());
    expect((result! as SubtitleIntentPreference).intent.language, 'eng');
  });

  test('item-change subtitle preference derives forced-ness from a forced title (#1716)', () {
    const committed = SubtitleTrack(id: 'source:4', title: 'FR Forced [ASS]', language: 'fra', codec: 'ass');

    final result = subtitlePreferenceForItemChange(
      hasCommittedSelection: true,
      committedTrack: committed,
      nativeTrack: SubtitleTrack.off,
    );

    expect(result, isA<SubtitleIntentPreference>());
    expect((result! as SubtitleIntentPreference).intent.forced, isTrue);
  });

  test('item-change subtitle preference preserves committed off and empty secondary slots', () {
    expect(
      subtitlePreferenceForItemChange(
        hasCommittedSelection: true,
        committedTrack: SubtitleTrack.off,
        nativeTrack: const SubtitleTrack(id: '7', language: 'eng'),
      ),
      const SubtitlePreference.off(),
    );
    expect(
      subtitlePreferenceForItemChange(
        hasCommittedSelection: true,
        committedTrack: null,
        nativeTrack: const SubtitleTrack(id: '8', language: 'swe'),
      ),
      const SubtitlePreference.off(),
    );
  });

  test('item-change subtitle preference uses native metadata only without a committed selection', () {
    final result = subtitlePreferenceForItemChange(
      hasCommittedSelection: false,
      committedTrack: null,
      nativeTrack: const SubtitleTrack(
        id: '9',
        title: 'English',
        language: 'eng',
        uri: 'https://example.test/old-episode/native.srt',
      ),
    );

    expect(result, isA<SubtitleIntentPreference>());
    expect((result! as SubtitleIntentPreference).intent.language, 'eng');
  });

  test('a declined committed off re-carries the declined preference (#1785)', () {
    const declined = SubtitlePreference.intent(
      SubtitleIntent(language: 'swe', forced: false, title: 'Swedish', codec: 'srt'),
    );

    // The committed off is fallout from a declined carry: with the player
    // also off, the declined preference itself keeps crossing boundaries.
    expect(
      subtitlePreferenceForItemChange(
        hasCommittedSelection: true,
        committedTrack: SubtitleTrack.off,
        nativeTrack: SubtitleTrack.off,
        declinedPreference: declined,
      ),
      declined,
    );
  });

  test('live native state outranks a declined carry after a late rescue (#1785)', () {
    const declined = SubtitlePreference.intent(
      SubtitleIntent(language: 'swe', forced: false, title: 'Swedish', codec: 'srt'),
    );

    final result = subtitlePreferenceForItemChange(
      hasCommittedSelection: true,
      committedTrack: SubtitleTrack.off,
      nativeTrack: const SubtitleTrack(id: '5', language: 'swe', title: 'Swedish', codec: 'srt'),
      declinedPreference: declined,
    );

    expect(result, isA<SubtitleIntentPreference>());
    expect((result! as SubtitleIntentPreference).intent.language, 'swe');
  });

  test('a declined stale source reference crosses the boundary as its intent (#1785)', () {
    const declined = SubtitlePreference.track(
      SubtitleTrack(id: 'source:9', title: 'Swedish', language: 'swe', codec: 'srt'),
    );

    final result = subtitlePreferenceForItemChange(
      hasCommittedSelection: true,
      committedTrack: SubtitleTrack.off,
      nativeTrack: SubtitleTrack.off,
      declinedPreference: declined,
    );

    expect(result, isA<SubtitleIntentPreference>());
    expect((result! as SubtitleIntentPreference).intent.language, 'swe');
  });

  test('a pick without source identity is committed raw and carries as an intent (#1785)', () {
    // The identity matcher failed (or the item has no subtitle rows): the
    // committed selection must still reflect the pick on screen, not the
    // session's previous choice.
    const picked = SubtitleTrack(id: '3', title: 'Swedish', language: 'swe', codec: 'srt');

    final selection = subtitleSelectionForUserPick(
      currentSelection: const PlaybackSubtitleSelection.off(),
      isPrimarySlot: true,
      track: picked,
    );

    expect(selection.primaryTrack, picked);
    expect(selection.primarySourceStreamId, isNull);
    expect(selection.primarySidecar, isNull);

    // Next episode boundary: the raw commit demotes to a semantic intent
    // instead of hardening the stale off.
    final carried = subtitlePreferenceForItemChange(
      hasCommittedSelection: true,
      committedTrack: selection.primaryTrack,
      nativeTrack: picked,
    );
    expect(carried, isA<SubtitleIntentPreference>());
    expect((carried! as SubtitleIntentPreference).intent.language, 'swe');
  });

  test('a source-backed pick keeps its source identity in the committed selection', () {
    final sourceTrack = MediaSubtitleTrack(
      id: 7,
      languageCode: 'swe',
      title: 'Swedish',
      codec: 'srt',
      selected: false,
      forced: false,
    );

    final selection = subtitleSelectionForUserPick(
      currentSelection: const PlaybackSubtitleSelection.off(),
      isPrimarySlot: true,
      track: const SubtitleTrack(id: '3', title: 'Swedish', language: 'swe', codec: 'srt'),
      sourceTrack: sourceTrack,
    );

    expect(selection.primaryTrack.id, 'source:7');
    expect(selection.primarySourceStreamId, 7);
  });

  test('a secondary-slot pick leaves the committed primary untouched', () {
    const primary = SubtitleTrack(id: 'source:4', title: 'Swedish', language: 'swe', codec: 'srt');
    const secondaryPick = SubtitleTrack(id: '5', title: 'English', language: 'eng', codec: 'srt');

    final selection = subtitleSelectionForUserPick(
      currentSelection: const PlaybackSubtitleSelection(primaryTrack: primary, primarySourceStreamId: 4),
      isPrimarySlot: false,
      track: secondaryPick,
    );

    expect(selection.primaryTrack, primary);
    expect(selection.primarySourceStreamId, 4);
    expect(selection.secondaryTrack, secondaryPick);
    expect(selection.secondarySourceStreamId, isNull);
  });

  test('a reload-path source subtitle pick becomes the session preference (#1785)', () {
    // Picks that cannot switch locally go through a full reload and never
    // reach the native remember chain; the authoritative source row still
    // has to become the session preference — including its discriminating
    // title — or a later fallback episode erases the choice.
    final rows = [
      MediaSubtitleTrack(
        id: 3,
        languageCode: 'eng',
        title: 'Full Subtitles',
        displayTitle: 'English',
        codec: 'ass',
        selected: true,
        forced: false,
      ),
      MediaSubtitleTrack(
        id: 4,
        languageCode: 'eng',
        title: 'Signs & Songs',
        displayTitle: 'English',
        codec: 'ass',
        selected: false,
        forced: false,
      ),
    ];

    final captured = sessionPreferenceForSourceSubtitleChoice(const PlaybackSourceSubtitleChoice.source(4), rows);
    expect(captured, isA<SubtitleTrackPreference>());
    expect((captured! as SubtitleTrackPreference).track.title, 'Signs & Songs');

    // The captured preference crosses the next episode boundary as its
    // intent, keeping the signs/dialogue distinction.
    final carried = SubtitlePreference.demoteToIntent(captured);
    expect(carried, isA<SubtitleIntentPreference>());
    expect((carried! as SubtitleIntentPreference).intent.title, 'Signs & Songs');
    expect((carried as SubtitleIntentPreference).intent.language, 'eng');
  });

  test('a reload-path off choice and a stale row id capture correctly', () {
    expect(
      sessionPreferenceForSourceSubtitleChoice(const PlaybackSourceSubtitleChoice.off(), const []),
      const SubtitlePreference.off(),
    );
    // A row the catalog no longer carries must not overwrite the session
    // preference with a fabricated pick.
    final rows = [MediaSubtitleTrack(id: 3, languageCode: 'eng', codec: 'ass', selected: false, forced: false)];
    expect(sessionPreferenceForSourceSubtitleChoice(const PlaybackSourceSubtitleChoice.source(99), rows), isNull);
  });

  test('a secondary-only change keeps the primary declined carry alive (#1785)', () {
    const declined = SubtitlePreference.intent(
      SubtitleIntent(language: 'swe', forced: false, title: 'Swedish', codec: 'srt'),
    );
    const current = PlaybackSubtitleSelection.off(declinedPreference: declined);

    final selection = subtitleSelectionForUserPick(
      currentSelection: current,
      isPrimarySlot: false,
      track: const SubtitleTrack(id: '5', title: 'English', language: 'eng', codec: 'srt'),
    );

    // The primary off stays fallout, not a decision: -1 must remain withheld
    // and the next boundary must still re-carry the intent.
    expect(selection.primaryTrack.id, SubtitleTrack.off.id);
    expect(selection.declinedPreference, declined);

    // A primary decision retires the carry.
    final decided = subtitleSelectionForUserPick(
      currentSelection: selection,
      isPrimarySlot: true,
      track: const SubtitleTrack(id: '3', title: 'Swedish', language: 'swe', codec: 'srt'),
    );
    expect(decided.declinedPreference, isNull);
  });

  testWidgets('initialization ownership serializes rollback, retry, and route removal', (tester) async {
    final failedDispose = Completer<void>();
    final replacementInitialize = Completer<bool>();
    final calls = <MethodCall>[];
    final eventCalls = <MethodCall>[];
    var initializeCount = 0;

    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) {
        calls.add(call);
        switch (call.method) {
          case 'initialize':
            initializeCount++;
            if (initializeCount == 2) return replacementInitialize.future;
            return Future<Object?>.value(true);
          case 'observeProperty':
            if (initializeCount == 1) {
              throw PlatformException(code: 'post_creation_failure', message: 'forced observation failure');
            }
            return Future<Object?>.value(null);
          case 'dispose':
            if (initializeCount == 1) return failedDispose.future;
            return Future<Object?>.value(null);
          default:
            return Future<Object?>.value(null);
        }
      },
      eventHandler: (call) async {
        eventCalls.add(call);
        return null;
      },
      testBody: () async {
        final key = GlobalKey<VideoPlayerScreenState>();
        await tester.pumpWidget(_screen(key));
        await pumpUntil(tester, () => calls.any((call) => call.method == 'dispose'));

        expect(key.currentState?.player, isNull);
        expect(find.widgetWithText(FilledButton, 'Retry'), findsNothing);
        expect(initializeCount, 1);
        expect(eventCalls.where((call) => call.method == 'cancel'), hasLength(1));

        failedDispose.complete();
        await pumpUntil(tester, () => find.widgetWithText(FilledButton, 'Retry').evaluate().isNotEmpty);

        final retryButton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Retry'));
        final retryFocusable = tester.widget<FocusableButton>(
          find.ancestor(of: find.widgetWithText(FilledButton, 'Retry'), matching: find.byType(FocusableButton)),
        );
        retryButton.onPressed!();
        retryFocusable.onPressed!();
        await pumpUntil(tester, () => initializeCount == 2);

        expect(initializeCount, 2);
        expect(key.currentState?.player, isNull);
        expect(calls.where((call) => call.method == 'dispose'), hasLength(1));
        expect(eventCalls.where((call) => call.method == 'cancel'), hasLength(1));

        await tester.pumpWidget(const SizedBox.shrink());
        replacementInitialize.completeError(PlatformException(code: 'late_failure', message: 'forced late failure'));
        await pumpUntil(tester, () => calls.where((call) => call.method == 'dispose').length == 2);

        expect(find.widgetWithText(FilledButton, 'Retry'), findsNothing);
        expect(initializeCount, 2);
        expect(calls.where((call) => call.method == 'dispose'), hasLength(2));
        expect(eventCalls.where((call) => call.method == 'cancel'), hasLength(2));
      },
    );
  });
}

Widget _screen(GlobalKey<VideoPlayerScreenState> key) {
  return ChangeNotifierProvider(
    create: (_) => PlaybackStateProvider(),
    child: MaterialApp(
      home: VideoPlayerScreen(
        key: key,
        metadata: testMediaItem(title: 'Lifecycle test video'),
        isOffline: true,
      ),
    ),
  );
}
