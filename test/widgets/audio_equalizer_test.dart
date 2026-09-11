import 'package:plezy/mpv/mpv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/models/audio_equalizer.dart';
import 'package:plezy/screens/settings/audio_equalizer_screen.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import '../test_helpers/prefs.dart';

void main() {
  setUp(() async {
    resetSharedPreferencesForTest();
    await SettingsService.getInstance();
    await LocaleSettings.setLocale(AppLocale.en);
  });

  Widget harness({EqualizerAudioType profile = EqualizerAudioType.global}) => TranslationProvider(
    child: InputModeTracker(
      child: MaterialApp(
        theme: monoTheme(dark: true),
        home: Scaffold(
          body: SingleChildScrollView(child: AudioEqualizerEditor(initialProfile: profile)),
        ),
      ),
    ),
  );

  testWidgets('fresh EQ opens with ten double-valued bands and no side-effect profiles', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(EqualizerGainControl), findsNWidgets(12));
    expect(SettingsService.instance.read(SettingsService.audioEqualizer).profiles, isEmpty);
    expect(find.text('Equalizer'), findsOneWidget);
  });

  testWidgets('codec entry inherits Global and editing creates only that override', (tester) async {
    final settings = SettingsService.instance;
    await settings.write(
      SettingsService.audioEqualizer,
      EqualizerSettings({
        EqualizerAudioType.global: EqualizerProfile(gains: AudioEqualizer.presetGains[EqualizerPreset.bass]!),
      }),
    );
    await tester.pumpWidget(harness(profile: EqualizerAudioType.eac3));
    await tester.pumpAndSettle();
    expect(find.text('Dolby Digital Plus'), findsOneWidget);
    final band = find.byKey(const ValueKey('eq-band-0'));
    expect(tester.widget<EqualizerGainControl>(band).value, 5);
    tester.widget<EqualizerGainControl>(band).onChanged(4.5);
    await tester.pumpAndSettle();
    final values = settings.read(SettingsService.audioEqualizer);
    expect(values.resolve(EqualizerAudioType.eac3).gains.first, 4.5);
    expect(values.resolve(EqualizerAudioType.global).gains.first, 5);
    expect(values.profiles.containsKey(EqualizerAudioType.dts), isFalse);
    expect(tester.takeException(), isNull);
    // Turning the effect off keeps all profiles.
    final before = values;
    await settings.write(SettingsService.audioEqualizerEnabled, true);
    await settings.write(SettingsService.audioEqualizerEnabled, false);
    expect(settings.read(SettingsService.audioEqualizer), before);
  });

  testWidgets('D-pad traverses without changing gain; Select edits; Back keeps editor open', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();
    final first = find.byKey(const ValueKey('eq-band-0'));
    final focus = find.descendant(of: first, matching: find.byType(Focus)).first;
    tester.widget<Focus>(focus).focusNode!.requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(SettingsService.instance.read(SettingsService.audioEqualizer).profiles, isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(
      SettingsService.instance.read(SettingsService.audioEqualizer).resolve(EqualizerAudioType.global).gains[1],
      0.5,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(AudioEqualizerEditor), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('player editor pins toggle beside profile while controls scroll', (tester) async {
    tester.view.physicalSize = const Size(900, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      TranslationProvider(
        child: InputModeTracker(
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 700,
                  height: 360,
                  child: AudioEqualizerEditor(initialProfile: EqualizerAudioType.eac3, player: _EqPlayer()),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final togglePosition = tester.getTopLeft(find.text('Equalizer'));
    await tester.drag(find.byKey(const ValueKey('eq-band-4')), const Offset(0, -180));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Equalizer')), togglePosition);
    expect(find.text('Dolby Digital Plus'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [390.0, 800.0, 1280.0]) {
    testWidgets('EQ has no overflow at width $width', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}

class _EqPlayer extends Fake implements Player {
  @override
  PlayerState get state => const PlayerState();
  @override
  PlayerStreams get streams => _EqStreams();

  @override
  bool get audioPassthroughActive => false;
}

class _EqStreams extends Fake implements PlayerStreams {
  @override
  Stream<PlayerLog> get log => const Stream.empty();
}
