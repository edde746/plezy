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
import 'package:plezy/theme/mono_tokens.dart';
import 'package:plezy/widgets/video_controls/sheets/video_settings_sheet.dart';

import '../test_helpers/prefs.dart';

const _testTokens = MonoTokens(
  radiusSm: 4,
  radiusMd: 8,
  radiusLg: 20,
  radiusXs: 5,
  groupGap: 2,
  space: 8,
  fast: Duration(milliseconds: 100),
  normal: Duration(milliseconds: 200),
  slow: Duration(milliseconds: 300),
  expressive: Duration(milliseconds: 300),
  bg: Colors.black,
  surface: Color(0xFF111111),
  outline: Color(0xFF333333),
  text: Colors.white,
  textMuted: Color(0xFFAAAAAA),
  splashFactory: NoSplash.splashFactory,
);

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
        theme: ThemeData(extensions: const [_testTokens]),
        home: const SubtitleStylingScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Переопределение ASS'));
    await tester.pumpAndSettle();

    final dialog = find.byType(AlertDialog);
    for (final label in ['Нет', 'Да', 'Масштабировать', 'Принудительно', 'Удалить стили']) {
      expect(find.descendant(of: dialog, matching: find.text(label)), findsOneWidget);
    }
  });
}

Future<void> _pumpSheet(WidgetTester tester, {bool canControl = false}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: const [_testTokens]),
      home: Scaffold(
        body: SizedBox(
          width: 900,
          height: 700,
          child: VideoSettingsSheet(
            player: _FakeSettingsPlayer(),
            audioSyncOffset: 0,
            subtitleSyncOffset: 0,
            canControl: canControl,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeSettingsPlayer implements Player {
  _FakeSettingsPlayer()
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

  @override
  PlayerState get state => const PlayerState();

  @override
  PlayerStreams get streams => _streams;

  @override
  String get playerType => 'exoplayer';

  @override
  Future<void> setAudioPassthrough(bool enabled) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
