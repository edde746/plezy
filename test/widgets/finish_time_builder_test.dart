import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/mpv/player/player_stream_controllers.dart';
import 'package:plezy/utils/formatters.dart';
import 'package:plezy/widgets/video_controls/widgets/finish_time_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await initializeDateFormatting('en');
  });

  // 30:50 left at 10:00:20 finishes at 10:31:10.
  const position = Duration(minutes: 10);
  const duration = Duration(minutes: 40, seconds: 50);

  testWidgets('pausing lets the finish time follow the wall clock (#2580)', (tester) async {
    var now = DateTime(2026, 10, 6, 10, 0, 20);
    final player = _FakePlayer(const PlayerState(playing: true, position: position, duration: duration));
    addTearDown(player.closeStreamControllers);
    await _pumpFinishTime(tester, player, () => now);
    expect(find.text('10:31'), findsOneWidget);

    // Playing: the playhead and the wall clock advance together.
    now = now.add(const Duration(seconds: 30));
    player.moveTo(position + const Duration(seconds: 30));
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('10:31'), findsOneWidget);

    player.announcePaused();
    await tester.pump(Duration.zero);
    expect(find.text('10:31'), findsOneWidget);

    // Paused, the finish time slides with the wall clock and flips exactly
    // when it crosses 10:32:00, 50 s later.
    now = now.add(const Duration(seconds: 49));
    await tester.pump(const Duration(seconds: 49));
    expect(find.text('10:31'), findsOneWidget);

    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('10:32'), findsOneWidget);

    // And it re-arms rather than firing once.
    now = now.add(const Duration(minutes: 1));
    await tester.pump(const Duration(minutes: 1));
    expect(find.text('10:33'), findsOneWidget);
  });

  testWidgets('a seek while paused re-reads the finish time and re-arms against it', (tester) async {
    var now = DateTime(2026, 10, 6, 10, 0, 20);
    final player = _FakePlayer(const PlayerState(position: position, duration: duration));
    addTearDown(player.closeStreamControllers);
    await _pumpFinishTime(tester, player, () => now);
    expect(find.text('10:31'), findsOneWidget);

    // Same whole minutes left (30), but the finish moves back across 10:31.
    player.moveTo(position + const Duration(seconds: 20));
    // Elapsing, even by zero, delivers the stream event before the frame.
    await tester.pump(Duration.zero);
    expect(find.text('10:30'), findsOneWidget);

    // 10:30:50 reaches 10:31:00 in 10 s, not in the 50 s armed before the seek.
    now = now.add(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('10:31'), findsOneWidget);
  });

  testWidgets('a buffering stall follows the wall clock like a pause', (tester) async {
    var now = DateTime(2026, 10, 6, 10, 0, 20);
    final player = _FakePlayer(
      const PlayerState(playing: true, buffering: true, position: position, duration: duration),
    );
    addTearDown(player.closeStreamControllers);
    await _pumpFinishTime(tester, player, () => now);
    expect(find.text('10:31'), findsOneWidget);

    now = now.add(const Duration(seconds: 50));
    await tester.pump(const Duration(seconds: 50));
    expect(find.text('10:32'), findsOneWidget);
  });

  testWidgets('resynchronises on resume after the process ran no timers', (tester) async {
    addTearDown(() => tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed));
    var now = DateTime(2026, 10, 6, 10, 0, 20);
    final player = _FakePlayer(const PlayerState(position: position, duration: duration));
    addTearDown(player.closeStreamControllers);
    await _pumpFinishTime(tester, player, () => now);
    expect(find.text('10:31'), findsOneWidget);

    // Suspended for five minutes: the wall clock moved, fake time did not.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = now.add(const Duration(minutes: 5));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('10:36'), findsOneWidget);
  });
}

Future<void> _pumpFinishTime(WidgetTester tester, Player player, DateTime Function() now) {
  return tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: FinishTimeBuilder(
        player: player,
        now: now,
        builder: (context, finishTime) =>
            Text(finishTime == null ? 'none' : formatClockTime(finishTime, is24Hour: true)),
      ),
    ),
  );
}

/// Player whose state the test moves; each change is announced on its stream
/// after the state updates, as `PlayerBase` does.
class _FakePlayer with PlayerStreamControllersMixin implements Player {
  _FakePlayer(this._state);

  PlayerState _state;

  @override
  PlayerState get state => _state;

  late final PlayerStreams _streams = createStreams();

  @override
  PlayerStreams get streams => _streams;

  void moveTo(Duration position) {
    _state = _state.copyWith(position: position);
    positionController.add(position);
  }

  void announcePaused() {
    _state = _state.copyWith(playing: false);
    playingController.add(false);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
