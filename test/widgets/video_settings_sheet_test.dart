import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/packed_stereo_layout.dart';
import 'package:plezy/mpv/models.dart';
import 'package:plezy/mpv/player/player.dart';
import 'package:plezy/mpv/player/player_native.dart';
import 'package:plezy/mpv/player/player_state.dart';
import 'package:plezy/mpv/player/player_streams.dart';
import 'package:plezy/screens/settings/subtitle_styling_screen.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/sleep_timer_service.dart';
import 'package:plezy/widgets/overlay_sheet.dart';
import 'package:plezy/widgets/video_controls/models/track_controls_state.dart';
import 'package:plezy/widgets/video_controls/sheets/video_settings_sheet.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

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

  testWidgets('keeps audio passthrough out of the in-player sheet', (tester) async {
    // It configures the audio output route, not this playback, and applying it
    // mid-stream bounces the audio renderer and re-decides video tunneling. Settings >
    // Video Playback owns it, alongside Tunneled Playback.
    await _pumpSheet(tester);

    // Positive control: land on the audio block that used to hold the toggle. Without
    // it, findsNothing below would also pass for an unbuilt or off-screen region, which
    // is what a bare scroll-then-assert silently degrades into. scrollUntilVisible
    // throws when the block is missing entirely, so the guard fails loudly instead.
    await tester.scrollUntilVisible(find.text('Normalize Loudness'), 300, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text('Downmix to Stereo'), findsOneWidget);

    expect(find.text('Audio Passthrough'), findsNothing);
  });

  testWidgets('shows the 3D UI toggle only for packed stereo playback', (tester) async {
    await _pumpSheet(tester, height: 1200);
    expect(find.text('3D Playback UI'), findsNothing);

    await _pumpSheet(
      tester,
      height: 1200,
      packedStereoLayout: PackedStereoLayout.sideBySideLeftFirst,
      onVideoZoomChanged: (_) {},
    );
    expect(find.text('3D Playback UI'), findsOneWidget);
    await tester.tap(find.text('Zoom'));
    await tester.pumpAndSettle();
    expect(find.text('Cannot change while playing 3D source'), findsOneWidget);
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

  testWidgets('offers requested playback speeds through 8x and persists the selection', (tester) async {
    final appliedRates = <double>[];
    final player = _FakeSettingsPlayer(
      onSetRate: (rate) async {
        appliedRates.add(rate);
      },
    );
    await _pumpSheetViaOverlayRoute(tester, player);

    await tester.tap(find.text('Playback Speed'));
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).last;
    for (final label in ['3.5x', '4x', '4.5x', '5x', '6x', '7x', '8x']) {
      await tester.scrollUntilVisible(find.text(label), 200, scrollable: scrollable);
      expect(find.text(label), findsOneWidget);
    }

    await tester.tap(find.text('8x'));
    await tester.pumpAndSettle();

    expect(appliedRates, [8.0]);
    expect(SettingsService.instance.read(SettingsService.defaultPlaybackSpeed), 8.0);
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
    final writes = <(String, String)>[];
    final player = _FakeSettingsPlayer(
      onSetProperty: (name, value) {
        writes.add((name, value));
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
    // The name carries as much weight as the count: the plane intercepts this
    // exact property, and any other name falls through to mpv as a real write.
    expect(writes, [('hdr-enabled', 'no')]);
  });

  // The switch springing back on its own reads as a lost tap. This message is
  // what tells the user the surface itself cannot carry HDR and no retry will
  // change that, so it has to survive any rework of the write path.
  testWidgets('a plane that can never carry HDR says so', (tester) async {
    final writes = <(String, String)>[];
    final player = _FakeSettingsPlayer(
      onSetProperty: (name, value) async {
        writes.add((name, value));
        throw PlatformException(code: 'HDR_UNSUPPORTED', message: 'no colour-management protocol');
      },
    );
    await _pumpSheet(tester, player: player, supportsHdrControl: true);
    await tester.scrollUntilVisible(find.text('HDR'), 500, scrollable: find.byType(Scrollable).first);

    final tile = find.ancestor(of: find.text('HDR'), matching: find.byType(ListTile)).first;
    final toggle = find.descendant(of: tile, matching: find.byType(Switch));
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(t.videoSettings.hdrUnsupported), findsOneWidget);
    // Once. A refusal is not something to compensate for: nothing was recorded,
    // so there is nothing to put back and no second write to explain.
    expect(writes, [('hdr-enabled', 'no')]);
    expect(tester.widget<Switch>(toggle).value, isTrue);
    expect(SettingsService.instance.read(SettingsService.enableHDR), isTrue);
  });

  testWidgets('an accepted HDR write pushes one hdr-enabled write per toggle', (tester) async {
    final writes = <(String, String)>[];
    final player = _FakeSettingsPlayer(onSetProperty: (name, value) async => writes.add((name, value)));
    await _pumpSheet(tester, player: player, supportsHdrControl: true);
    await tester.scrollUntilVisible(find.text('HDR'), 500, scrollable: find.byType(Scrollable).first);

    final tile = find.ancestor(of: find.text('HDR'), matching: find.byType(ListTile)).first;
    final toggle = find.descendant(of: tile, matching: find.byType(Switch));
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(writes, [('hdr-enabled', 'no')]);
    expect(tester.widget<Switch>(toggle).value, isFalse);
    expect(SettingsService.instance.read(SettingsService.enableHDR), isFalse);

    // Toggled back so the expectation cannot be met by a sheet that sends 'no'
    // whichever way the switch went.
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(writes, [('hdr-enabled', 'no'), ('hdr-enabled', 'yes')]);
    expect(tester.widget<Switch>(toggle).value, isTrue);
    expect(SettingsService.instance.read(SettingsService.enableHDR), isTrue);
  });

  testWidgets('hides the HDR controls when the host declares the surface cannot carry HDR', (tester) async {
    await _pumpSheet(tester);

    // Scroll past where the HDR rows would sit. Without a following anchor the
    // absence would also be satisfied by the ListView simply not having built
    // that far yet, which is not the contract under test.
    await tester.scrollUntilVisible(find.text('Auto-Play Next'), 500, scrollable: find.byType(Scrollable).first);

    expect(find.text('HDR'), findsNothing);
    expect(find.text('HDR Tone Mapping'), findsNothing);
  });

  // The sheet resolves both the capability probe and the tone-mapping row through
  // PlayerNative.usesLinuxVideoPlane, so setting the documented override puts the
  // plane's behaviour under test on any host.
  group('on the Linux video plane', () {
    setUp(() {
      PlayerNative.debugUseLinuxVideoPlane = true;
    });

    tearDown(() {
      PlayerNative.debugUseLinuxVideoPlane = null;
    });

    // supportsHdrControl left null so the sheet asks the player, which is the path
    // that ships on Linux. The cases above inject the answer and so cover only the
    // gate, not the probe behind it.
    testWidgets('hides the HDR controls when the capability probe answers no', (tester) async {
      final player = _FakeSettingsPlayer(hdrOutputSupported: false);
      await _pumpSheet(tester, player: player, supportsHdrControl: null, height: 4000);

      expect(find.text('Auto-Play Next'), findsOneWidget, reason: 'the list should be fully built');
      expect(find.text('HDR'), findsNothing);
      expect(find.text('HDR Tone Mapping'), findsNothing);
    });

    testWidgets('a player reporting an HDR output reveals the controls', (tester) async {
      final player = _FakeSettingsPlayer(hdrOutputSupported: true);
      await _pumpSheet(tester, player: player, supportsHdrControl: null, height: 4000);

      expect(find.text('HDR'), findsOneWidget);
      expect(find.text('HDR Tone Mapping'), findsOneWidget);
    });

    // Dragging the window onto an HDR monitor raises no lifecycle event on
    // Wayland, so this stream is the sheet's only notice that the probe now
    // answers differently.
    testWidgets('an HDR output arriving under the window reveals the controls', (tester) async {
      final player = _FakeSettingsPlayer(hdrOutputSupported: false);
      await _pumpSheet(tester, player: player, supportsHdrControl: null, height: 4000);
      expect(find.text('HDR'), findsNothing);

      player.hdrOutputSupported = true;
      player.hdrOutputChanged.add(null);
      await tester.pumpAndSettle();

      expect(find.text('HDR'), findsOneWidget);
      expect(find.text('HDR Tone Mapping'), findsOneWidget);
    });

    testWidgets('losing the HDR output takes the controls away again', (tester) async {
      final player = _FakeSettingsPlayer(hdrOutputSupported: true);
      await _pumpSheet(tester, player: player, supportsHdrControl: null, height: 4000);
      expect(find.text('HDR'), findsOneWidget);

      player.hdrOutputSupported = false;
      player.hdrOutputChanged.add(null);
      await tester.pumpAndSettle();

      expect(find.text('Auto-Play Next'), findsOneWidget, reason: 'the list should be fully built');
      expect(find.text('HDR'), findsNothing);
      expect(find.text('HDR Tone Mapping'), findsNothing);
    });

    testWidgets('the output-changed subscription does not outlive the sheet', (tester) async {
      final player = _FakeSettingsPlayer(hdrOutputSupported: false);
      await _pumpSheet(tester, player: player, supportsHdrControl: null, height: 4000);
      final probesWhileMounted = player.probeCount;

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pumpAndSettle();

      player.hdrOutputSupported = true;
      player.hdrOutputChanged.add(null);
      await tester.pumpAndSettle();

      // The plane outlives any one sheet, so a subscription left behind keeps
      // probing - and setState()s - on a disposed State.
      expect(player.hdrOutputChanged.hasListener, isFalse);
      expect(player.probeCount, probesWhileMounted);
      expect(tester.takeException(), isNull);
    });

    testWidgets('selecting a tone-mapping mode pushes it to mpv and persists it', (tester) async {
      final writes = <(String, String)>[];
      final player = _FakeSettingsPlayer(onSetProperty: (name, value) async => writes.add((name, value)));
      await _pumpSheet(tester, player: player, supportsHdrControl: true, withSheetHost: true);
      await tester.scrollUntilVisible(find.text('HDR Tone Mapping'), 500, scrollable: find.byType(Scrollable).first);

      await tester.tap(find.text('HDR Tone Mapping'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Player'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(writes, [('hdr-tone-mapping', 'player')]);
      expect(SettingsService.instance.read(SettingsService.hdrToneMapping), HdrToneMapping.player);
    });

    testWidgets('a refused tone-mapping write leaves the stored mode alone', (tester) async {
      final writes = <(String, String)>[];
      final player = _FakeSettingsPlayer(
        onSetProperty: (name, value) async {
          writes.add((name, value));
          throw StateError('rejected');
        },
      );
      await _pumpSheet(tester, player: player, supportsHdrControl: true, withSheetHost: true);
      await tester.scrollUntilVisible(find.text('HDR Tone Mapping'), 500, scrollable: find.byType(Scrollable).first);

      await tester.tap(find.text('HDR Tone Mapping'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Player'));
      await tester.pumpAndSettle();

      // mpv is asked before the setting is written, precisely so a refusal
      // cannot leave the stored mode claiming one the player never entered.
      expect(tester.takeException(), isNull);
      expect(writes, [('hdr-tone-mapping', 'player')]);
      expect(SettingsService.instance.read(SettingsService.hdrToneMapping), HdrToneMapping.compositor);
    });
  });

  // The refusals covered above all come from the player. This is the other half:
  // the player takes the value and the store loses it, which is the case that
  // used to leave the plane carrying a policy neither the sheet nor the stored
  // preference named for the rest of the session.
  group('when the preference store refuses the write', () {
    late _RejectingPrefsStore store;

    setUp(() async {
      // The tone-mapping row is gated on the plane. Installing the store belongs
      // out here too: SharedPreferencesWithCache binds the platform when it is
      // created, and creating it reads the store off disk, which a testWidgets
      // body cannot await.
      PlayerNative.debugUseLinuxVideoPlane = true;
      store = _RejectingPrefsStore(
        // Seeded with the values both controls start on, so a rejected write is
        // a rejected *overwrite* and the surviving value is an explicit one
        // rather than the absence of a key.
        initial: {SettingsService.enableHDR.key: true, SettingsService.hdrToneMapping.key: 'compositor'},
        refused: {SettingsService.enableHDR.key, SettingsService.hdrToneMapping.key},
      );
      SharedPreferencesAsyncPlatform.instance = store;
      // resetSharedPreferencesForTest already registered the teardown that puts
      // the previous platform back.
      BaseSharedPreferencesService.resetForTesting();
      SettingsService.resetForTesting();
      await SettingsService.getInstance();
    });

    tearDown(() {
      PlayerNative.debugUseLinuxVideoPlane = null;
    });

    testWidgets('a lost HDR preference write puts the plane back on the stored policy', (tester) async {
      final writes = <(String, String)>[];
      final player = _FakeSettingsPlayer(onSetProperty: (name, value) async => writes.add((name, value)));
      await _pumpSheet(tester, player: player, supportsHdrControl: true);
      await tester.scrollUntilVisible(find.text('HDR'), 500, scrollable: find.byType(Scrollable).first);

      final tile = find.ancestor(of: find.text('HDR'), matching: find.byType(ListTile)).first;
      final toggle = find.descendant(of: tile, matching: find.byType(Switch));
      expect(tester.widget<Switch>(toggle).value, isTrue);

      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // The plane accepted 'no' and the store then lost it, so the plane has to
      // be told 'yes' again. Leaving it at 'no' is the divergence.
      expect(writes, [('hdr-enabled', 'no'), ('hdr-enabled', 'yes')]);
      expect(tester.widget<Switch>(toggle).value, isTrue);
      expect(SettingsService.instance.read(SettingsService.enableHDR), isTrue);
      expect(await store.durable(SettingsService.enableHDR.key), isTrue);
    });

    testWidgets('a lost tone-mapping preference write puts the plane back on the stored mode', (tester) async {
      final writes = <(String, String)>[];
      final player = _FakeSettingsPlayer(onSetProperty: (name, value) async => writes.add((name, value)));
      await _pumpSheet(tester, player: player, supportsHdrControl: true, withSheetHost: true);
      await tester.scrollUntilVisible(find.text('HDR Tone Mapping'), 500, scrollable: find.byType(Scrollable).first);

      await tester.tap(find.text('HDR Tone Mapping'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Player'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(writes, [('hdr-tone-mapping', 'player'), ('hdr-tone-mapping', 'compositor')]);
      expect(SettingsService.instance.read(SettingsService.hdrToneMapping), HdrToneMapping.compositor);
      expect(await store.durable(SettingsService.hdrToneMapping.key), 'compositor');
      // The pick did not take, so the picker stays open with the tick where it
      // was. A tick on 'Player' would mean the sheet is showing a mode the
      // stored preference does not name.
      expect(_tickOn('Compositor'), findsOneWidget);
      expect(_tickOn('Player'), findsNothing);
    });
  });
}

/// The tick marking the selected option in one of the sheet's picker views.
Finder _tickOn(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(ListTile)).first,
  matching: find.byIcon(Symbols.check_rounded),
);

Future<void> _pumpSheet(
  WidgetTester tester, {
  bool canControl = false,
  Player? player,
  // Explicitly false by default so the sheet does not consult the platform.
  // Pass null to exercise the capability probe instead.
  bool? supportsHdrControl = false,
  // Option views that dismiss themselves on selection reach
  // OverlaySheetController.of(), which asserts without a host above it.
  bool withSheetHost = false,
  // The default is short enough that the ListView is lazy: callers that need a
  // row present without dragging to it pass a taller sheet, which builds all of
  // them.
  double height = 700,
  PackedStereoLayout packedStereoLayout = PackedStereoLayout.unknown,
  ValueChanged<double>? onVideoZoomChanged,
}) async {
  final sheet = SizedBox(
    width: 900,
    height: height,
    child: VideoSettingsSheet(
      player: player ?? _FakeSettingsPlayer(),
      supportsHdrControl: supportsHdrControl,
      trackControlsState: TrackControlsState(
        canControl: canControl,
        packedStereoLayout: packedStereoLayout,
        onVideoZoomChanged: onVideoZoomChanged,
      ),
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: const [testMonoTokensAnimated]),
      home: Scaffold(body: withSheetHost ? OverlaySheetHost(child: sheet) : sheet),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpSheetViaOverlayRoute(WidgetTester tester, Player player) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: const [testMonoTokensAnimated]),
      home: OverlaySheetHost(
        child: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => unawaited(
                OverlaySheetController.of(context).show<void>(
                  builder: (_) => VideoSettingsSheet(
                    player: player,
                    trackControlsState: const TrackControlsState(canControl: true),
                  ),
                ),
              ),
              child: const Text('Open settings'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open settings'));
  await tester.pumpAndSettle();
}

class _FakeSettingsPlayer implements Player {
  _FakeSettingsPlayer({this.onSetProperty, this.onSetRate, this.hdrOutputSupported = false});

  /// The plane's notice that the output under the window changed, which is the
  /// only thing that moves [isHdrOutputSupported]'s answer while a sheet is up.
  /// Closed by [dispose], which the tests that emit on it call through
  /// `addTearDown`.
  final hdrOutputChanged = StreamController<void>.broadcast();

  @override
  Future<void> dispose({bool preserveDisplayMode = false}) async {
    await hdrOutputChanged.close();
  }

  late final PlayerStreams _streams = PlayerStreams(
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
    hdrOutputChanged: hdrOutputChanged.stream,
  );

  final Future<void> Function(String name, String value)? onSetProperty;
  final Future<void> Function(double rate)? onSetRate;
  bool hdrOutputSupported;
  int probeCount = 0;

  @override
  Future<bool> isHdrOutputSupported() async {
    probeCount++;
    return hdrOutputSupported;
  }

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
  Future<void> setRate(double rate) {
    return onSetRate?.call(rate) ?? Future<void>.value();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A preference store that loses the durable half of a write.
///
/// Substituting the platform is how this suite supplies a store at all (see
/// [resetSharedPreferencesForTest]), and it is the only layer that can be lost:
/// `SharedPreferencesWithCache` sits above it and is not subclassable.
final class _RejectingPrefsStore extends InMemorySharedPreferencesAsync {
  _RejectingPrefsStore({required Map<String, Object> initial, required this.refused}) : super.withData(initial);

  /// Only these keys. Creating the cache runs the legacy-to-async migration,
  /// which stores its own completion marker and must be allowed to.
  final Set<String> refused;

  /// What survived, which is what the next launch reads. Not
  /// `SettingsService.read`: that answers from the in-process copy, which a
  /// refused write moves before the platform call it then fails.
  Future<Object?> durable(String key) async {
    final stored = await getPreferences(
      GetPreferencesParameters(filter: PreferencesFilters(allowList: {key})),
      const SharedPreferencesOptions(),
    );
    return stored[key];
  }

  Future<bool> _refuse(String key) async => throw StateError('the preference store refused "$key"');

  @override
  Future<bool> setBool(String key, bool value, SharedPreferencesOptions options) =>
      refused.contains(key) ? _refuse(key) : super.setBool(key, value, options);

  @override
  Future<bool> setString(String key, String value, SharedPreferencesOptions options) =>
      refused.contains(key) ? _refuse(key) : super.setString(key, value, options);
}
