import 'dart:async';
import 'dart:ui' show PointerDeviceKind, SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/live_tv_timeline.dart';
import 'package:plezy/models/livetv_program.dart';
import 'package:plezy/models/livetv_channel.dart';
import 'package:plezy/mpv/player/player_streams.dart';
import 'package:plezy/screens/video_player/live_tv_session_state.dart';
import 'package:plezy/services/live_tv_program_guide.dart';
import 'package:plezy/services/live_seek_accumulator.dart';
import 'package:plezy/utils/formatters.dart';
import 'package:plezy/widgets/video_controls/widgets/live_timeline_bar.dart';
import 'package:plezy/widgets/video_controls/widgets/video_controls_header.dart';
import 'package:plezy/watch_together/providers/watch_together_provider.dart';
import 'package:plezy/widgets/video_controls/widgets/timeline_slider.dart';
import 'package:plezy/widgets/video_controls/painters/buffer_range_painter.dart';

import '../test_helpers/watch_together_fakes.dart';
import '../test_helpers/media_items.dart';
import '../test_helpers/theme.dart';

const _start = 1767268800.0;

final _previewPrograms = [
  LiveTvProgram(title: 'Previous', beginsAt: _start.toInt(), endsAt: _start.toInt() + 120),
  LiveTvProgram(title: 'Current', beginsAt: _start.toInt() + 120, endsAt: _start.toInt() + 240),
];

LiveTvTimeline _timeline({
  double? position = 60,
  double? pending,
  bool estimated = false,
  bool unknown = false,
  bool withBuffer = true,
  bool withProgram = true,
  LiveTvProgram? program,
  double bufferStart = 30,
  double bufferEnd = 180,
  double metadataNow = 60,
}) => LiveTvTimeline.resolve(
  playback: LiveTvPlaybackPosition(
    epoch: position == null ? null : _start + position,
    active: !unknown,
    accuracy: unknown
        ? LiveTvTimeAccuracy.unknown
        : estimated
        ? LiveTvTimeAccuracy.estimated
        : LiveTvTimeAccuracy.confirmed,
  ),
  seekable: withBuffer ? LiveTvSeekWindow(startEpoch: _start + bufferStart, endEpoch: _start + bufferEnd) : null,
  programs: withProgram
      ? [program ?? LiveTvProgram(title: 'Morning news', beginsAt: _start.toInt(), endsAt: _start.toInt() + 120)]
      : [],
  pendingSeekEpoch: pending == null ? null : _start + pending,
  metadataNowEpoch: _start + metadataNow,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await initializeDateFormatting('en');
  });

  testWidgets('remote program preview follows direction changes without moving playback', (tester) async {
    final acc = LiveSeekAccumulator(
      seek: (_) async => true,
      currentEpoch: () => _start + 150,
      bounds: () => const LiveSeekBounds(startEpoch: _start, endEpoch: _start + 230),
    );
    addTearDown(acc.dispose);
    final duration = formatDurationTextual(120000);
    for (final (delta, title, position) in [
      (-40, 'Previous', 110000),
      (20, 'Current', 10000),
      (-40, 'Previous', 90000),
    ]) {
      acc.seekBy(delta, previewProgram: true);
      final view = LiveTvTimeline.resolve(
        playback: const LiveTvPlaybackPosition(
          epoch: _start + 150,
          accuracy: LiveTvTimeAccuracy.estimated,
          active: true,
        ),
        pendingSeekEpoch: acc.pendingEpoch,
        programPreviewEpoch: acc.programPreviewEpoch,
        seekable: acc.bounds(),
        programs: _previewPrograms,
        metadataNowEpoch: _start + 180,
      );
      await _pump(tester, timeline: view, seeks: [], showHeader: true);
      expect(find.text('$title · $duration'), findsOneWidget);
      expect(_slider(tester).value, position);
      expect(view.playback.epoch, _start + 150);
    }
    acc.cancel();
  });

  for (final outcome in ['success', 'failure', 'cancel']) {
    testWidgets('remote program preview stays visible until seek $outcome', (tester) async {
      final state = LiveTvSessionState(null);
      final initial = state.beginClockOpen(_start + 150);
      state.bindClockOpen(initial, 1);
      state.calibrateClockSource(const PlayerSourceReady(sourceId: 1, position: Duration.zero));
      final result = Completer<bool>();
      final acc = LiveSeekAccumulator(
        seek: (target) async {
          final open = state.beginClockOpen(target);
          final success = await result.future;
          if (success) {
            state.bindClockOpen(open, 2);
            state.calibrateClockSource(const PlayerSourceReady(sourceId: 2, position: Duration.zero));
          } else {
            state.failClockOpen(open);
          }
          return success;
        },
        currentEpoch: () => state.playbackPosition(Duration.zero).epoch,
        bounds: () => const LiveSeekBounds(startEpoch: _start, endEpoch: _start + 230),
      );
      addTearDown(acc.dispose);
      LiveTvTimeline view() => LiveTvTimeline.resolve(
        playback: state.playbackPosition(Duration.zero),
        pendingSeekEpoch: acc.pendingEpoch,
        programPreviewEpoch: acc.programPreviewEpoch,
        seekStatus: state.seekStatus,
        seekable: acc.bounds(),
        programs: _previewPrograms,
        metadataNowEpoch: _start + 180,
      );
      final player = FakeSyncPlayer();
      addTearDown(player.dispose);
      Future<void> refresh() =>
          _pump(tester, timeline: view(), timelineBuilder: (_) => view(), seeks: [], player: player, showHeader: true);
      final duration = formatDurationTextual(120000);
      await refresh();
      expect(find.text('Current · $duration'), findsOneWidget);
      acc.seekBy(-60, previewProgram: true);
      await refresh();
      expect(find.text('Previous · $duration'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      await refresh();
      expect(find.text('Previous · $duration'), findsOneWidget);
      expect(_slider(tester).value, 90000);
      if (outcome == 'cancel') {
        acc.cancel();
        state.cancelClockOpens();
      }
      result.complete(outcome == 'success');
      await tester.pump();
      await refresh();
      expect(acc.programPreviewEpoch, isNull);
      expect(find.text('${outcome == 'success' ? 'Previous' : 'Current'} · $duration'), findsOneWidget);
      expect(_timelineSlider(tester).showPosition, outcome == 'success');
    });
  }

  testWidgets('program labels cover full schedule while scrubbing clamps to playable intersection', (tester) async {
    final seeks = <double>[];
    await _pump(tester, timeline: _timeline(), seeks: seeks);
    expect(find.textContaining('Morning news'), findsNothing);
    expect(find.text(_clock(_start)), findsOneWidget);
    expect(find.text(_clock(_start + 120)), findsOneWidget);
    await _tapTrack(tester, 0);
    await _tapTrack(tester, 1);
    expect(seeks, [_start + 30, _start + 119]);
  });

  testWidgets('Plex estimated source switches to previous program only after readiness and plays across the boundary', (
    tester,
  ) async {
    final duration = formatDurationTextual(120000);
    final state = LiveTvSessionState(null);
    var position = Duration.zero;
    final programs = [
      LiveTvProgram(title: 'Previous program', beginsAt: _start.toInt(), endsAt: _start.toInt() + 120),
      LiveTvProgram(title: 'Live program', beginsAt: _start.toInt() + 120, endsAt: _start.toInt() + 240),
    ];
    LiveTvTimeline view(Duration position) => LiveTvTimeline.resolve(
      playback: state.playbackPosition(position),
      pendingSeekEpoch: state.pendingTargetEpoch,
      seekStatus: state.seekStatus,
      programs: programs,
      seekable: const LiveTvSeekWindow(startEpoch: _start, endEpoch: _start + 200),
      metadataNowEpoch: _start + 180,
    );
    final first = state.beginClockOpen(_start + 180);
    state.bindClockOpen(first, 1);
    state.calibrateClockSource(const PlayerSourceReady(sourceId: 1, position: Duration.zero));
    await _pump(tester, timeline: view(position), seeks: [], showHeader: true);
    expect(find.text('Live program · $duration'), findsOneWidget);
    expect(find.text('Test channel'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Live program · $duration')).dy,
      greaterThan(tester.getTopLeft(find.text('Test channel')).dy),
    );

    final rewind = state.beginClockOpen(_start + 60);
    await _pump(tester, timeline: view(position), seeks: [], showHeader: true);
    expect(find.text('Live program · $duration'), findsOneWidget);
    expect(find.text('Previous program · $duration'), findsNothing);
    state.bindClockOpen(rewind, 2);
    position = const Duration(seconds: 52);
    state.calibrateClockSource(PlayerSourceReady(sourceId: 2, position: position));
    await _pump(tester, timeline: view(position), seeks: [], showHeader: true);
    expect(find.text('Previous program · $duration'), findsOneWidget);
    expect(find.text(_clock(_start)), findsOneWidget);
    expect(find.text(_clock(_start + 120)), findsOneWidget);
    expect(_slider(tester).value, 60000);
    expect(view(position).playback.confirmedEpoch, isNull);

    // A further pending seek must not revert the title to the live program.
    final next = state.beginClockOpen(_start + 30);
    await _pump(tester, timeline: view(position), seeks: [], showHeader: true);
    expect(find.text('Previous program · $duration'), findsOneWidget);
    state.failClockOpen(next);
    await _pump(tester, timeline: view(position), seeks: [], showHeader: true);
    expect(find.text('Previous program · $duration'), findsOneWidget);

    final resumed = state.beginClockOpen(_start + 60);
    state.bindClockOpen(resumed, 3);
    state.calibrateClockSource(PlayerSourceReady(sourceId: 3, position: position));
    final tickingPlayer = _PositionPlayer();
    addTearDown(tickingPlayer.dispose);
    position = const Duration(seconds: 111, milliseconds: 999);
    tickingPlayer.setPosition(position);
    await _pump(tester, timeline: view(position), seeks: [], showHeader: true);
    expect(find.text('Previous program · $duration'), findsOneWidget);
    await _pump(
      tester,
      timeline: view(position),
      timelineBuilder: view,
      seeks: [],
      showHeader: true,
      player: tickingPlayer,
    );
    // Keep the player snapshot behind the event so both widgets must use
    // the supplied stream position rather than an external variable or state.
    tickingPlayer.positions.add(const Duration(seconds: 112));
    await tester.pump();
    await tester.pump();
    expect(find.text('Live program · $duration'), findsOneWidget);
    expect(find.text(_clock(_start + 120)), findsOneWidget);
    expect(find.text(_clock(_start + 240)), findsOneWidget);
    expect(_slider(tester).value, 0);
    tickingPlayer.positions.add(const Duration(seconds: 113));
    await tester.pump();
    await tester.pump();
    expect(_slider(tester).value, 1000);
  });

  testWidgets('accessibility relative skips use full buffer across the program boundary', (tester) async {
    final semantics = tester.ensureSemantics();
    final relative = <int>[];
    final absolute = <double>[];
    await _pump(tester, timeline: _timeline(position: 115, pending: 145), seeks: absolute, relative: relative);
    final node = tester.getSemantics(find.bySemanticsLabel(t.videoControls.timelineSlider));
    expect(node.getSemanticsData().value, _clock(_start + 115));
    expect(node.getSemanticsData().increasedValue, _clock(_start + 155));
    node.owner!.performAction(node.id, SemanticsAction.increase);
    expect(relative, [10]);
    expect(absolute, isEmpty);
    expect(find.textContaining(t.liveTv.timelinePending), findsNothing);
    semantics.dispose();
  });

  testWidgets('real session estimates show LIVE until playback falls behind the fresh edge', (tester) async {
    final semantics = tester.ensureSemantics();
    final state = LiveTvSessionState(null);
    final open = state.beginClockOpen(_start + 60);
    state.bindClockOpen(open, 1);
    state.calibrateClockSource(const PlayerSourceReady(sourceId: 1, position: Duration.zero));
    var edge = _start + 60;
    LiveTvTimeline view() => LiveTvTimeline.resolve(
      playback: state.playbackPosition(Duration.zero),
      programs: [LiveTvProgram(title: 'News', beginsAt: _start.toInt(), endsAt: _start.toInt() + 120)],
      liveEdgeEpoch: edge,
      liveEdgeAccuracy: LiveTvTimeAccuracy.estimated,
      metadataNowEpoch: edge,
    );
    final player = FakeSyncPlayer();
    addTearDown(player.dispose);
    await _pump(tester, timeline: view(), seeks: [], player: player);
    String announcedPosition() =>
        tester.getSemantics(find.bySemanticsLabel(t.videoControls.timelineSlider)).getSemanticsData().value;
    expect(announcedPosition(), t.liveTv.live);
    expect(view().playback.confirmedEpoch, isNull);
    expect(view().playback.accuracy, LiveTvTimeAccuracy.estimated);

    // Paused playback stays put while the server's live edge advances.
    edge += 16;
    await _pump(tester, timeline: view(), seeks: [], player: player);
    expect(announcedPosition(), '${t.liveTv.timelineEstimated}: ${_clock(_start + 60)}');
    expect(view().isAtLive, isFalse);
    semantics.dispose();
  });

  testWidgets('out-of-window fallback hides playback without inventing an edge timestamp', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, timeline: _timeline(position: -30), seeks: []);
    expect(find.textContaining(t.liveTv.timelineLiveProgram), findsNothing);
    final node = tester.getSemantics(find.bySemanticsLabel(t.videoControls.timelineSlider));
    expect(node.getSemanticsData().value, t.liveTv.timelineUnavailable);
    expect(_timelineSlider(tester).showPosition, isFalse);
    expect(_painter(tester).progressPosition, isNull);
    semantics.dispose();
  });

  testWidgets('estimated and pending positions reuse the movie playhead without visible status text', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, timeline: _timeline(estimated: true), seeks: []);
    final initialThumb = _thumbSize(tester);
    expect(initialThumb, isNotNull);
    expect(_slider(tester).value, 60000);
    expect(find.text(_clock(_start)), findsOneWidget);
    expect(find.text(_clock(_start + 120)), findsOneWidget);

    await _pump(tester, timeline: _timeline(estimated: true, pending: 90), seeks: []);
    expect(_thumbSize(tester), initialThumb);
    expect(_slider(tester).value, 90000);
    expect(_painter(tester).progressPosition, const Duration(seconds: 90));
    final node = tester.getSemantics(find.bySemanticsLabel(t.videoControls.timelineSlider));
    expect(node.getSemanticsData().value, '${t.liveTv.timelineEstimated}: ${_clock(_start + 60)}');
    expect(find.textContaining(t.liveTv.timelineEstimated), findsNothing);
    expect(find.textContaining(t.liveTv.timelinePending), findsNothing);
    expect(find.textContaining(t.liveTv.timelineLiveProgram), findsNothing);
    expect(find.text(_clock(_start)), findsOneWidget);
    expect(find.text(_clock(_start + 120)), findsOneWidget);
    semantics.dispose();
  });

  for (final is24Hour in [true, false]) {
    testWidgets('hover shows and updates seconds with is24Hour=$is24Hour', (tester) async {
      await _pump(tester, timeline: _timeline(estimated: true), seeks: [], is24Hour: is24Hour);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      final rect = tester.getRect(find.byType(TimelineSlider));
      for (final second in [45, 46, 119]) {
        await mouse.moveTo(Offset(rect.left + rect.width * second / 120, rect.center.dy));
        await tester.pump();
        expect(find.text(_clock(_start + second, is24Hour: is24Hour, includeSeconds: true)), findsOneWidget);
        expect(
          tester.getRect(find.text(_clock(_start + second, is24Hour: is24Hour, includeSeconds: true))).right,
          lessThanOrEqualTo(rect.right),
        );
      }
      expect(find.text(_clock(_start, is24Hour: is24Hour)), findsOneWidget);
      expect(find.text(_clock(_start + 120, is24Hour: is24Hour)), findsOneWidget);
      expect(find.textContaining(t.liveTv.timelineEstimated), findsNothing);
      await mouse.moveTo(Offset.zero);
      await tester.pump();
      expect(find.text(_clock(_start + 119, is24Hour: is24Hour, includeSeconds: true)), findsNothing);
      await mouse.removePointer();
    });
  }

  testWidgets('scrubbing retains the same thumb and previews the clamped target', (tester) async {
    final seeks = <double>[];
    await _pump(tester, timeline: _timeline(estimated: true), seeks: seeks);
    final initialThumb = _thumbSize(tester);
    final rect = tester.getRect(find.byType(TimelineSlider));
    final gesture = await tester.startGesture(Offset(rect.left, rect.center.dy));
    await tester.pump();
    expect(_slider(tester).value, 30000);
    expect(_painter(tester).progressPosition, const Duration(seconds: 30));
    expect(find.text(_clock(_start + 30, includeSeconds: true)), findsOneWidget);
    expect(_thumbSize(tester), initialThumb);
    await gesture.moveTo(Offset(rect.right - 1, rect.center.dy));
    await tester.pump();
    expect(_slider(tester).value, 119000);
    expect(_painter(tester).progressPosition, const Duration(seconds: 119));
    expect(_slider(tester).thumbColor, Colors.red);
    expect(find.text(_clock(_start + 119, includeSeconds: true)), findsOneWidget);
    expect(_thumbSize(tester), initialThumb);
    await gesture.up();
    await tester.pump();
    expect(seeks, [_start + 119]);
  });

  testWidgets('retained interval uses the existing movie buffer painter', (tester) async {
    await _pump(tester, timeline: _timeline(), seeks: []);
    final painter = _painter(tester);
    expect(painter.duration, const Duration(seconds: 120));
    expect(painter.ranges.single.start, const Duration(seconds: 30));
    expect(painter.ranges.single.end, const Duration(seconds: 120));
    expect(_slider(tester).activeColor, Colors.transparent);
    expect(_slider(tester).thumbColor, Colors.red);
    expect(painter.progressColor, Colors.red);
    expect(painter.progressPosition, const Duration(seconds: 60));
  });

  testWidgets('program changes while dragging cancel the old target', (tester) async {
    var current = _timeline();
    final seeks = <double>[];
    await _pump(tester, timeline: current, timelineBuilder: (_) => current, seeks: seeks);
    final gesture = await tester.startGesture(tester.getCenter(find.byType(TimelineSlider)));
    await tester.pump();
    current = _timeline(withProgram: false);
    await gesture.up();
    await tester.pump();
    expect(seeks, isEmpty);
  });

  testWidgets('refreshing the same airing preserves an active scrub despite new metadata objects', (tester) async {
    final guide = LiveTvProgramGuide();
    final owner = Object();
    final channel = LiveTvChannel(key: 'A');
    Future<void> refresh(String title) async {
      await guide.refresh(
        owner: owner,
        channel: channel,
        fromEpoch: _start,
        toEpoch: _start + 120,
        fetch: (_, _) async => [
          LiveTvProgram(
            ratingKey: 'news',
            channelIdentifier: 'A',
            title: title,
            beginsAt: _start.toInt(),
            endsAt: _start.toInt() + 120,
          ),
        ],
      );
    }

    await refresh('News');
    LiveTvTimeline view() => _timeline(program: guide.programs.single, estimated: true);
    final seeks = <double>[];
    await _pump(tester, timeline: view(), timelineBuilder: (_) => view(), seeks: seeks);
    final gesture = await tester.startGesture(tester.getCenter(find.byType(TimelineSlider)));
    await tester.pump();
    await refresh('Updated news title');
    await gesture.up();
    await tester.pump();
    expect(seeks, [_start + 60]);
  });

  testWidgets('an unchanged airing without a server ID also survives guide refresh', (tester) async {
    var current = _timeline();
    final seeks = <double>[];
    await _pump(tester, timeline: current, timelineBuilder: (_) => current, seeks: seeks);
    final gesture = await tester.startGesture(tester.getCenter(find.byType(TimelineSlider)));
    await tester.pump();
    current = _timeline();
    await gesture.up();
    await tester.pump();
    expect(seeks, [_start + 60]);
  });

  for (final change in ['airing', 'channel', 'bounds']) {
    testWidgets('a real $change change cancels an active scrub', (tester) async {
      LiveTvProgram program({bool changed = false}) => LiveTvProgram(
        ratingKey: changed && change == 'airing' ? 'other-news' : 'news',
        channelIdentifier: changed && change == 'channel' ? 'B' : 'A',
        title: 'News',
        beginsAt: _start.toInt(),
        endsAt: _start.toInt() + (changed && change == 'bounds' ? 121 : 120),
      );
      var current = _timeline(program: program());
      final seeks = <double>[];
      await _pump(tester, timeline: current, timelineBuilder: (_) => current, seeks: seeks);
      final gesture = await tester.startGesture(tester.getCenter(find.byType(TimelineSlider)));
      await tester.pump();
      current = _timeline(program: program(changed: true));
      await gesture.up();
      await tester.pump();
      expect(seeks, isEmpty);
    });
  }

  testWidgets('unknown and unavailable timelines never paint a playhead or seek', (tester) async {
    final semantics = tester.ensureSemantics();
    final seeks = <double>[];
    await _pump(tester, timeline: _timeline(unknown: true, withBuffer: false, withProgram: false), seeks: seeks);
    final data = tester.getSemantics(find.bySemanticsLabel(t.videoControls.timelineSlider)).getSemanticsData();
    expect(data.flagsCollection.isEnabled, Tristate.isFalse);
    expect(data.hasAction(SemanticsAction.increase), isFalse);
    expect(_timelineSlider(tester).showPosition, isFalse);
    expect(_painter(tester).progressPosition, isNull);
    await _tapTrack(tester, 0.5);
    expect(seeks, isEmpty);
    semantics.dispose();
  });

  testWidgets('missing history explicitly uses buffer range', (tester) async {
    await _pump(tester, timeline: _timeline(withProgram: false), seeks: [], showHeader: true);
    expect(find.text('Test channel'), findsOneWidget);
    expect(find.descendant(of: find.byType(VideoControlsHeader), matching: find.byType(Text)), findsOneWidget);
    expect(find.text(t.liveTv.timelineBuffer), findsNothing);
    expect(find.text(_clock(_start + 30)), findsOneWidget);
    expect(find.text(_clock(_start + 180)), findsOneWidget);
  });

  testWidgets('program with no overlapping buffer disables pointer scrub', (tester) async {
    final seeks = <double>[];
    await _pump(tester, timeline: _timeline(bufferStart: 130), seeks: seeks);
    await _tapTrack(tester, 0.5);
    expect(seeks, isEmpty);
    expect(_painter(tester).ranges, isEmpty);
  });

  testWidgets('disabled controls and desktop focus routing remain intact', (tester) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    var presses = 0;
    final seeks = <double>[];
    await _pump(
      tester,
      timeline: _timeline(),
      seeks: seeks,
      focus: focus,
      onKey: (_, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowRight) {
          presses++;
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    );
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(presses, 1);
    await _pump(tester, timeline: _timeline(), seeks: seeks, enabled: false);
    await _tapTrack(tester, 0.5);
    expect(seeks, isEmpty);
  });
}

TimelineSlider _timelineSlider(WidgetTester tester) => tester.widget<TimelineSlider>(find.byType(TimelineSlider));
Slider _slider(WidgetTester tester) => tester.widget<Slider>(find.byType(Slider));
Size? _thumbSize(WidgetTester tester) =>
    tester.widget<SliderTheme>(find.byType(SliderTheme)).data.thumbSize?.resolve({});
BufferRangePainter _painter(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(
              find.byWidgetPredicate((widget) => widget is CustomPaint && widget.painter is BufferRangePainter),
            )
            .painter!
        as BufferRangePainter;

Future<void> _tapTrack(WidgetTester tester, double fraction) async {
  final rect = tester.getRect(find.byType(TimelineSlider));
  final gesture = await tester.startGesture(Offset(rect.left + (rect.width - 1) * fraction, rect.center.dy));
  await tester.pump();
  await gesture.up();
  await tester.pump();
}

String _clock(double epoch, {bool is24Hour = true, bool includeSeconds = false}) => formatClockTime(
  DateTime.fromMillisecondsSinceEpoch((epoch * 1000).round()),
  is24Hour: is24Hour,
  includeSeconds: includeSeconds,
);

Future<void> _pump(
  WidgetTester tester, {
  required LiveTvTimeline timeline,
  required List<double> seeks,
  LiveTvTimeline Function(Duration)? timelineBuilder,
  List<int>? relative,
  bool enabled = true,
  bool showHeader = false,
  FakeSyncPlayer? player,
  bool is24Hour = true,
  FocusNode? focus,
  KeyEventResult Function(FocusNode, KeyEvent)? onKey,
}) async {
  final activePlayer = player ?? FakeSyncPlayer(position: const Duration(seconds: 60));
  if (player == null) addTearDown(activePlayer.dispose);
  final watchTogether = WatchTogetherProvider();
  addTearDown(watchTogether.dispose);
  await tester.pumpWidget(
    TranslationProvider(
      child: ChangeNotifierProvider<WatchTogetherProvider>.value(
        value: watchTogether,
        child: MaterialApp(
          theme: ThemeData(extensions: const [testMonoTokens]),
          home: MediaQuery(
            data: MediaQueryData(alwaysUse24HourFormat: is24Hour),
            child: Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showHeader)
                        VideoControlsHeader(
                          metadata: testMediaItem(title: 'Test channel', durationMs: 999000),
                          player: activePlayer,
                          liveTimelineForPosition: timelineBuilder ?? (_) => timeline,
                          showClock: false,
                          style: VideoHeaderStyle.singleLine,
                        ),
                      LiveTimelineBar(
                        player: activePlayer,
                        timelineForPosition: timelineBuilder ?? (_) => timeline,
                        onSeekEnd: seeks.add,
                        onSeekBy: relative?.add,
                        enabled: enabled,
                        focusNode: focus,
                        onKeyEvent: onKey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

// Only position is read by the header and timeline in this test.
class _PositionStreams implements PlayerStreams {
  @override
  final Stream<Duration> position;
  _PositionStreams(this.position);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PositionPlayer extends FakeSyncPlayer {
  final positions = StreamController<Duration>.broadcast();
  late final _positionStreams = _PositionStreams(positions.stream);

  @override
  PlayerStreams get streams => _positionStreams;

  @override
  Future<void> dispose({bool preserveDisplayMode = false}) async {
    await positions.close();
    await super.dispose(preserveDisplayMode: preserveDisplayMode);
  }
}
