import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/mpv/models.dart';
import 'package:plezy/mpv/player/player.dart';
import 'package:plezy/mpv/player/player_state.dart';
import 'package:plezy/mpv/player/player_streams.dart';
import 'package:plezy/screens/settings/subtitle_styling_screen.dart';
import 'package:plezy/services/sleep_timer_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/widgets/video_controls/sheets/video_settings_sheet.dart';

import '../test_helpers/prefs.dart';
import '../test_helpers/theme.dart';

void main() {
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.ru);
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  setUp(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    SleepTimerService().cancelTimer();
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  tearDown(() {
    SleepTimerService().cancelTimer();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('shows audio passthrough on supported TV-style surfaces', (tester) async {
    await _pumpSheet(tester);

    await tester.scrollUntilVisible(find.text('Audio Passthrough'), 500, scrollable: find.byType(Scrollable).first);

    expect(find.text('Audio Passthrough'), findsOneWidget);
  });

  testWidgets('localizes Off, Normal, and Active video setting values', (tester) async {
    LocaleSettings.setLocaleSync(AppLocale.ru);

    await _pumpSheet(tester, canControl: true);
    expect(find.text('Обычная'), findsOneWidget);
    expect(find.text('Выкл.'), findsOneWidget);

    final sleepTimer = SleepTimerService();
    sleepTimer.startTimer(const Duration(hours: 1), () {});
    try {
      await tester.pump();
      expect(find.textContaining('Активен ('), findsOneWidget);
    } finally {
      sleepTimer.cancelTimer();
    }
  });

  testWidgets('localizes every ASS subtitle override enum label', (tester) async {
    LocaleSettings.setLocaleSync(AppLocale.ru);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [testMonoTokensAnimated]),
        home: const SubtitleStylingScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Переопределение ASS'));
    await tester.pumpAndSettle();

    final dialog = find.byType(AlertDialog);
    for (final label in ['Нет', 'Да', 'Масштаб', 'Принудительно', 'Удалить стили']) {
      expect(find.descendant(of: dialog, matching: find.text(label)), findsOneWidget);
    }
  });

  testWidgets('failed HDR write restores the toggle without persisting', (tester) async {
    final propertyWrite = Completer<void>();
    var writeCount = 0;
    final player = _FakeSettingsPlayer(
      onSetProperty: (_, _) {
        writeCount++;
        return propertyWrite.future;
      },
    );
    await _pumpSheet(tester, player: player, supportsHdrControl: true);
    await tester.scrollUntilVisible(find.text('HDR'), 500, scrollable: find.byType(Scrollable).first);

    final tile = find.ancestor(of: find.text('HDR'), matching: find.byType(ListTile)).first;
    final toggle = find.descendant(of: tile, matching: find.byType(Switch));
    expect(tester.widget<Switch>(toggle).value, isTrue);

    await tester.tap(toggle);
    await tester.pump();
    expect(tester.widget<Switch>(toggle).value, isFalse);
    expect(SettingsService.instance.read(SettingsService.enableHDR), isTrue);

    propertyWrite.completeError(StateError('rejected'));
    await tester.pump();
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));

    expect(tester.takeException(), isNull);
    expect(tester.widget<Switch>(toggle).value, isTrue);
    expect(SettingsService.instance.read(SettingsService.enableHDR), isTrue);
    expect(writeCount, 1);
  });

  testWidgets('accepted HDR write persists once', (tester) async {
    var writeCount = 0;
    final player = _FakeSettingsPlayer(
      onSetProperty: (_, _) async {
        writeCount++;
      },
    );
    await _pumpSheet(tester, player: player, supportsHdrControl: true);
    await tester.scrollUntilVisible(find.text('HDR'), 500, scrollable: find.byType(Scrollable).first);

    final tile = find.ancestor(of: find.text('HDR'), matching: find.byType(ListTile)).first;
    final toggle = find.descendant(of: tile, matching: find.byType(Switch));
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(writeCount, 1);
    expect(tester.widget<Switch>(toggle).value, isFalse);
    expect(SettingsService.instance.read(SettingsService.enableHDR), isFalse);
  });
}

Future<void> _pumpSheet(
  WidgetTester tester, {
  bool canControl = false,
  Player? player,
  bool supportsHdrControl = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: const [testMonoTokensAnimated]),
      home: Scaffold(
        body: SizedBox(
          width: 900,
          height: 700,
          child: VideoSettingsSheet(
            player: player ?? _FakeSettingsPlayer(),
            audioSyncOffset: 0,
            subtitleSyncOffset: 0,
            canControl: canControl,
            supportsHdrControl: supportsHdrControl,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeSettingsPlayer implements Player {
  _FakeSettingsPlayer({this.onSetProperty})
    : _streams = PlayerStreams(
        playing: const Stream<bool>.empty(),
        completed: const Stream<bool>.empty(),
        buffering: const Stream<bool>.empty(),
        position: const Stream<Duration>.empty(),
        duration: const Stream<Duration>.empty(),
        seekable: const Stream<bool>.empty(),
        buffer: const Stream<Duration>.empty(),
        volume: const Stream<double>.empty(),
        rate: const Stream<double>.empty(),
        tracks: const Stream<Tracks>.empty(),
        track: const Stream<TrackSelection>.empty(),
        log: const Stream<PlayerLog>.empty(),
        error: const Stream<PlayerError>.empty(),
        audioDevice: const Stream<AudioDevice>.empty(),
        audioDevices: const Stream<List<AudioDevice>>.empty(),
        bufferRanges: const Stream<List<BufferRange>>.empty(),
        playbackRestart: const Stream<void>.empty(),
        backendSwitched: const Stream<void>.empty(),
      );

  final PlayerStreams _streams;
  final Future<void> Function(String name, String value)? onSetProperty;

  @override
  PlayerState get state => const PlayerState();

  @override
  PlayerStreams get streams => _streams;

  @override
  String get playerType => 'exoplayer';

  @override
  Future<void> setAudioPassthrough(bool enabled) async {}

  @override
  Future<void> setProperty(String name, String value) {
    return onSetProperty?.call(name, value) ?? Future<void>.value();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
