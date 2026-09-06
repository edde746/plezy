import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:plezy/database/app_database.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/video_volume_controller.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/watch_together/providers/watch_together_provider.dart';
import 'package:plezy/widgets/video_controls/desktop_video_controls.dart';
import 'package:plezy/widgets/video_controls/player_chrome_controller.dart';
import 'package:plezy/widgets/video_controls/video_controls.dart';
import 'package:plezy/widgets/video_controls/widgets/player_toast_indicator.dart';
import 'package:plezy/widgets/video_controls/widgets/skip_marker_button.dart';
import 'package:plezy/focus/dpad_navigator.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';
import '../test_helpers/theme.dart';

/// Pressing Enter on the player surface used to raise the chrome *and* drop
/// focus onto Play/Pause, while the global input-mode tracker separately
/// switched the whole app into keyboard mode — even with "Video Player
/// Navigation" off. Enter activates whatever already has focus; it is not a
/// request to start navigating, so it must leave focus where the viewer left it
/// while still doing its job. Tab and a remote's OK remain the deliberate ways
/// into the OSD.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _TogglePlayer player;
  late PlayerChromeController chrome;
  late PlayerToastController toast;
  late VideoVolumeController volume;
  late PlaybackStateProvider playbackState;
  late WatchTogetherProvider watchTogether;
  late AppDatabase database;
  late ValueNotifier<bool> hasFirstFrame;
  late SettingsService settings;
  late FocusNode screenFocusNode;
  var toggles = 0;

  /// What the player screen would have done with each Back that escaped the
  /// controls. The harness cannot run the real staged chain, so it records the
  /// disposition the screen would have resolved: an empty list means the
  /// controls answered the press themselves.
  final screenBackDispositions = <PlayerBackDisposition>[];

  /// Back key-downs that reached the screen node. A stage that claims the press
  /// consumes the down as well as the up, so this separates "the controls
  /// declined the press" from "a later guard handed it back".
  var screenBackKeyDowns = 0;

  Future<void> setNavigationEnabled(bool value) => settings.write(SettingsService.videoPlayerNavigationEnabled, value);

  setUp(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await initializeDateFormatting('en');
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    settings = await SettingsService.getInstance();

    // Desktop with a pointer: the configuration the report came from.
    TvDetectionService.debugSetAppleTVOverride(false);
    PlatformDetector.debugSetIsDesktopOSOverride(true);

    database = AppDatabase.forTesting(NativeDatabase.memory());
    player = _TogglePlayer();
    chrome = PlayerChromeController(initiallyVisible: false);
    toast = PlayerToastController();
    volume = VideoVolumeController(player: player, settings: settings, initialVolume: 100);
    playbackState = PlaybackStateProvider();
    watchTogether = WatchTogetherProvider();
    hasFirstFrame = ValueNotifier<bool>(true);
    screenFocusNode = FocusNode(debugLabel: 'VideoPlayerScreen');
    toggles = 0;
    screenBackDispositions.clear();
    screenBackKeyDowns = 0;
  });

  tearDown(() async {
    TvDetectionService.debugSetAppleTVOverride(null);
    TvDetectionService.setForceTVSync(false);
    PlatformDetector.debugSetIsDesktopOSOverride(null);
    hasFirstFrame.dispose();
    screenFocusNode.dispose();
    volume.dispose();
    playbackState.dispose();
    watchTogether.dispose();
    chrome.dispose();
    toast.dispose();
    await player.close();
    await database.close();
  });

  /// Mirrors the production tree: the screen-level node autofocuses during the
  /// loading phase and already holds the remote by the time the controls mount,
  /// so the controls' own `autofocus` cannot win it back. Without that, the
  /// surface would take focus by default and the startup claim would look
  /// correct even when it is not.
  Widget shell(Widget child, {TargetPlatform platform = TargetPlatform.windows}) => InputModeTracker(
    child: MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        ChangeNotifierProvider<PlaybackStateProvider>.value(value: playbackState),
        ChangeNotifierProvider<WatchTogetherProvider>.value(value: watchTogether),
      ],
      child: MaterialApp(
        theme: ThemeData(platform: platform, extensions: const [testMonoTokens]),
        home: Scaffold(
          body: SizedBox(
            width: 1280,
            height: 720,
            child: Focus(
              focusNode: screenFocusNode,
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent && event.logicalKey.isBackKey) screenBackKeyDowns++;
                if (event is KeyUpEvent && event.logicalKey.isBackKey) {
                  screenBackDispositions.add(
                    resolvePlayerBackDisposition(
                      navigationKey: classifyPlayerNavigationKey(event, isAppleTV: PlatformDetector.isAppleTV()),
                      contentStripVisible: chrome.contentStripVisible,
                      controlsVisible: chrome.controlsVisible,
                      physicalEscapeExitsFullscreen: false,
                    ),
                  );
                }
                return KeyEventResult.ignored;
              },
              child: child,
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> pumpPlayer(
    WidgetTester tester, {
    List<MediaMarker>? markers,
    TargetPlatform platform = TargetPlatform.windows,
    bool canControl = true,
    bool playbackPromptOpen = false,
  }) async {
    await tester.pumpWidget(shell(const SizedBox.expand(), platform: platform));
    await tester.pump();
    expect(screenFocusNode.hasPrimaryFocus, isTrue, reason: 'precondition: the screen node owns the remote');

    await tester.pumpWidget(
      shell(
        platform: platform,
        PlexVideoControls(
          player: player,
          volumeController: volume,
          metadata: testMediaItem(id: 'select-key'),
          initialMarkers: markers,
          toastController: toast,
          chromeController: chrome,
          hasFirstFrame: hasFirstFrame,
          canNavigateMediaItems: false,
          canControl: canControl,
          playbackPromptOpen: playbackPromptOpen,
          onPlayPauseRequested: (_) async => toggles++,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyDownEvent(key);
    await tester.pump();
    await tester.sendKeyUpEvent(key);
    await tester.pumpAndSettle();
  }

  String? focusLabel() => FocusManager.instance.primaryFocus?.debugLabel;

  InputMode currentMode(WidgetTester tester) =>
      InputModeTracker.of(tester.element(find.byType(PlexVideoControls)), listen: false);

  /// Mounts the player, runs [body], then unmounts and disarms the auto-hide
  /// timer so the harness's pending-timer check stays honest.
  void playerTest(
    String description,
    Future<void> Function(WidgetTester tester) body, {
    List<MediaMarker>? markers,
    TargetPlatform platform = TargetPlatform.windows,
    bool canControl = true,
    bool playbackPromptOpen = false,
  }) {
    testWidgets(description, (tester) async {
      await pumpPlayer(
        tester,
        markers: markers,
        platform: platform,
        canControl: canControl,
        playbackPromptOpen: playbackPromptOpen,
      );
      await body(tester);
      chrome.cancelAutoHide();
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  group('player navigation disabled', () {
    setUp(() => setNavigationEnabled(false));

    playerTest('the player surface, not the screen node, owns the remote once mounted', (tester) async {
      expect(focusLabel(), 'PlayerSurface');
    });

    playerTest('Enter raises the chrome and toggles playback without taking focus', (tester) async {
      await press(tester, LogicalKeyboardKey.enter);

      expect(chrome.controlsVisible, isTrue, reason: 'Select is the show-me-the-controls affordance');
      expect(toggles, 1);
      expect(focusLabel(), 'PlayerSurface', reason: 'a keyboard Enter must not start a focus session');
      expect(currentMode(tester), InputMode.pointer, reason: 'and must not arm focus chrome app-wide');
    });

    playerTest('Enter keeps toggling once the chrome is up', (tester) async {
      await press(tester, LogicalKeyboardKey.enter);
      await press(tester, LogicalKeyboardKey.enter);

      expect(toggles, 2, reason: 'Select must not become a one-shot key when the chrome is visible');
      expect(focusLabel(), 'PlayerSurface');
    });

    playerTest('a remote OK does hand the chrome focus', (tester) async {
      await press(tester, LogicalKeyboardKey.select);

      expect(chrome.controlsVisible, isTrue);
      expect(focusLabel(), 'PlayPause', reason: 'a remote has no pointer, so OK is a navigation request');
      expect(currentMode(tester), InputMode.keyboard);
    });

    playerTest('Tab is the keyboard way into the OSD, and keeps traversing inside it', (tester) async {
      await press(tester, LogicalKeyboardKey.tab);
      expect(chrome.controlsVisible, isTrue);
      expect(focusLabel(), 'PlayPause', reason: 'Tab with the chrome down raises it and hands it focus');

      // The surface handler must not swallow Tab once focus is inside the OSD,
      // or the viewer is stranded on the control Tab first landed on.
      await press(tester, LogicalKeyboardKey.tab);
      expect(
        focusLabel(),
        isNot(anyOf('PlayPause', 'PlayerSurface')),
        reason: 'app-level NextFocusAction must reach the next OSD control',
      );
    });

    playerTest('an arrow seeks without switching the app into keyboard mode', (tester) async {
      await press(tester, LogicalKeyboardKey.arrowRight);

      expect(currentMode(tester), InputMode.pointer, reason: 'arrows are playback shortcuts here');
      expect(focusLabel(), 'PlayerSurface');
    });
  });

  group('player navigation enabled', () {
    setUp(() => setNavigationEnabled(true));

    playerTest('Enter shows the chrome and toggles, leaving focus put', (tester) async {
      await press(tester, LogicalKeyboardKey.enter);

      expect(chrome.controlsVisible, isTrue);
      expect(toggles, 1);
      // Opting into player navigation buys arrow keys, not a focus session from
      // a plain Enter: focus and input mode move together or not at all.
      expect(focusLabel(), 'PlayerSurface');
      expect(currentMode(tester), InputMode.pointer);
    });

    playerTest('ArrowUp raises the chrome onto Play/Pause', (tester) async {
      await press(tester, LogicalKeyboardKey.arrowUp);

      expect(chrome.controlsVisible, isTrue);
      expect(focusLabel(), 'PlayPause');
      expect(currentMode(tester), InputMode.keyboard);
    });

    playerTest('ArrowUp hands focus over when the chrome is already up', (tester) async {
      chrome.show();
      await tester.pumpAndSettle();
      expect(focusLabel(), 'PlayerSurface', reason: 'precondition: nothing in the chrome owns focus');

      await press(tester, LogicalKeyboardKey.arrowUp);

      expect(focusLabel(), 'PlayPause', reason: 'the arrow must not be consumed into a dead end');
    });

    playerTest('a horizontal arrow hands focus over when the chrome is already up', (tester) async {
      chrome.show();
      await tester.pumpAndSettle();
      expect(focusLabel(), 'PlayerSurface', reason: 'precondition: nothing in the chrome owns focus');

      await press(tester, LogicalKeyboardKey.arrowRight);

      // The surface only owns horizontals while the chrome is down, so this
      // arrow promotes the app into keyboard mode; focus has to become visible
      // with it or the two diverge.
      expect(currentMode(tester), InputMode.keyboard);
      expect(focusLabel(), 'PlayPause', reason: 'the arrow must not be consumed into a dead end');
    });

    playerTest('a horizontal arrow seeks under the chrome without arming focus', (tester) async {
      await press(tester, LogicalKeyboardKey.arrowRight);

      expect(currentMode(tester), InputMode.pointer, reason: 'a hidden-chrome seek is not navigation');
      expect(chrome.controlsVisible, isFalse);
    });
  });

  playerTest('the OSD focus entry point is raw mechanism, not policy', (tester) async {
    await setNavigationEnabled(false);
    chrome.show();
    await tester.pumpAndSettle();

    // Internal hand-offs — the skip-marker button's ArrowDown, an item swap —
    // must keep working even with navigation off and no keyboard session.
    tester.state<DesktopVideoControlsState>(find.byType(DesktopVideoControls)).requestPlayPauseFocus();
    await tester.pumpAndSettle();

    expect(focusLabel(), 'PlayPause');
  });

  playerTest('hiding in the frame gap after show cannot strand controlsPresented', (tester) async {
    chrome.show(restartAutoHide: false);
    // One pump: the subtree mounts at opacity 0 and the post-frame callback
    // flips the fade-in target on — but the fade-in build has not run yet.
    await tester.pump();

    // A pointer exit landing in that gap must not trust an opaque flag the
    // renderer never realized: hide() retires presentation immediately, and
    // the never-started fade-in cannot strand the flag behind a fade-out
    // whose onEnd will never fire.
    expect(chrome.hide(), isTrue);
    await tester.pump();

    expect(chrome.controlsVisible, isFalse);
    expect(chrome.controlsPresented, isFalse, reason: 'back must resolve to the route pop, not hide-the-chrome');
  });

  // The player surface must own the remote from the moment it mounts, whatever
  // the chrome is doing. When it does not, the screen node answers the first
  // key with its chrome-raising self-heal instead of a playback shortcut.
  group('startup hands the remote to the player surface', () {
    setUp(() {
      chrome.dispose();
      chrome = PlayerChromeController(initiallyVisible: true);
    });

    playerTest('when the route opens with the chrome already up (desktop)', (tester) async {
      expect(focusLabel(), 'PlayerSurface');
    });

    playerTest('and Enter there toggles playback instead of raising a self-heal', (tester) async {
      await press(tester, LogicalKeyboardKey.enter);

      expect(toggles, 1);
      expect(focusLabel(), 'PlayerSurface');
      expect(currentMode(tester), InputMode.pointer);
    });
  });

  group('startup on a television', () {
    setUp(() async {
      TvDetectionService.debugSetAppleTVOverride(true);
      PlatformDetector.debugSetIsDesktopOSOverride(false);
      await setNavigationEnabled(true);
    });

    // A TV route opens with the chrome down, navigation on and keyboard mode
    // already active — the exact combination that used to skip the claim.
    playerTest('the surface owns the remote even though the chrome starts down', (tester) async {
      expect(chrome.controlsVisible, isFalse);
      expect(focusLabel(), 'PlayerSurface');
    });
  });

  // Declining a skip prompt is the mirror of taking it. Back used to fall
  // through to the screen's staged chain and exit the player outright, so the
  // only key on a remote that means "no thanks" also ended the episode.
  // Desktop, not TV, because Apple TV runs Back on key-down: the normal
  // down-consume/up-act path is where the claim has to hold.
  group('declining a skip prompt', () {
    final introMarker = MediaMarker(id: 1, type: 'intro', startTimeOffset: 10000, endTimeOffset: 45000);

    Future<void> showPrompt(WidgetTester tester) async {
      player.emitPosition(const Duration(seconds: 15));
      await tester.pumpAndSettle();
      expect(find.byType(SkipMarkerButton), findsOneWidget, reason: 'precondition: the prompt is up');
    }

    playerTest('Back hides the prompt without skipping or exiting', markers: [introMarker], (tester) async {
      await showPrompt(tester);

      await press(tester, LogicalKeyboardKey.gameButtonB);

      expect(find.byType(SkipMarkerButton), findsNothing, reason: 'the prompt is declined');
      expect(player.state.position, const Duration(seconds: 15), reason: 'declining must not skip');
      expect(focusLabel(), 'PlayerSurface', reason: 'the vanished button must hand the remote back');
      expect(screenBackDispositions, isEmpty, reason: 'the press must not reach the exit chain');
    });

    playerTest('the next Back belongs to the screen again', markers: [introMarker], (tester) async {
      await showPrompt(tester);

      await press(tester, LogicalKeyboardKey.gameButtonB);
      await press(tester, LogicalKeyboardKey.gameButtonB);

      expect(screenBackDispositions, [PlayerBackDisposition.exitPlayer], reason: 'one press declines, the next leaves');
    });

    // The button's own 7s auto-dismiss is armed for every prompt while
    // auto-skip is off, which is the default. handleBackKeyAction acts on the
    // key-up, so a timer landing mid-press used to flip the gate and hand the
    // press to the screen -- exiting the player on the very press meant to
    // keep it open.
    playerTest('a mid-press auto-dismiss cannot turn the press into an exit', markers: [introMarker], (tester) async {
      await showPrompt(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.gameButtonB);
      await tester.pump();
      await tester.pump(const Duration(seconds: 8));
      expect(find.byType(SkipMarkerButton), findsNothing, reason: 'precondition: the timer fired mid-press');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.gameButtonB);
      await tester.pumpAndSettle();

      expect(screenBackDispositions, isEmpty, reason: 'the claim is latched for the whole press');
    });

    playerTest('physical Escape declines it too, having no fullscreen role here', markers: [introMarker], (
      tester,
    ) async {
      await showPrompt(tester);

      await press(tester, LogicalKeyboardKey.escape);

      expect(find.byType(SkipMarkerButton), findsNothing);
      expect(screenBackDispositions, isEmpty, reason: 'Escape must not exit the player either');
    });

    playerTest('a screen-level prompt keeps its own Back', markers: [introMarker], playbackPromptOpen: true, (
      tester,
    ) async {
      await showPrompt(tester);

      await press(tester, LogicalKeyboardKey.gameButtonB);

      expect(find.byType(SkipMarkerButton), findsOneWidget, reason: 'the prompt is not ours to answer');
      expect(screenBackKeyDowns, 1, reason: 'the press is never claimed, not merely handed back');
      expect(screenBackDispositions, isNotEmpty, reason: 'the prompt stage lives on the screen');
    });

    playerTest('a viewer who cannot skip keeps their exit press', markers: [introMarker], canControl: false, (
      tester,
    ) async {
      await showPrompt(tester);

      await press(tester, LogicalKeyboardKey.gameButtonB);

      expect(find.byType(SkipMarkerButton), findsOneWidget, reason: 'the button is inert, not dismissable');
      expect(screenBackDispositions, [PlayerBackDisposition.exitPlayer]);
    });

    playerTest('the chrome owns a press that starts under it', markers: [introMarker], (tester) async {
      await showPrompt(tester);
      chrome.show();
      await tester.pumpAndSettle();

      await press(tester, LogicalKeyboardKey.gameButtonB);

      expect(screenBackKeyDowns, 1, reason: 'the press is never claimed, not merely handed back');
      expect(screenBackDispositions, [PlayerBackDisposition.hideControls]);
    });

    // The gesture the feature exists for: "no thanks" while the countdown runs.
    playerTest('declining stops a running auto-skip countdown', markers: [introMarker], (tester) async {
      await settings.write(SettingsService.skipIntroMode, SkipMarkerMode.auto);
      await showPrompt(tester);

      await press(tester, LogicalKeyboardKey.gameButtonB);
      await tester.pump(const Duration(seconds: 10));

      expect(player.state.position, const Duration(seconds: 15), reason: 'a declined countdown must not fire');
      expect(screenBackDispositions, isEmpty);
    });

    // #2138: Off means the marker is invisible — no prompt, no countdown, and
    // Back goes straight to the screen because there is nothing to decline.
    playerTest('an Off marker kind plays through without a prompt', markers: [introMarker], (tester) async {
      await settings.write(SettingsService.skipIntroMode, SkipMarkerMode.off);
      player.emitPosition(const Duration(seconds: 15));
      await tester.pump(const Duration(seconds: 10));

      expect(find.byType(SkipMarkerButton), findsNothing);
      expect(player.state.position, const Duration(seconds: 15));

      await press(tester, LogicalKeyboardKey.gameButtonB);
      expect(screenBackDispositions, [PlayerBackDisposition.exitPlayer], reason: 'nothing to decline');
    });

    playerTest('switching a marker kind Off drops a prompt already up', markers: [introMarker], (tester) async {
      await showPrompt(tester);

      await settings.write(SettingsService.skipIntroMode, SkipMarkerMode.off);
      await tester.pumpAndSettle();

      expect(find.byType(SkipMarkerButton), findsNothing);
      expect(player.state.position, const Duration(seconds: 15));
    });

    playerTest(
      'an Off intro does not silence a credits prompt',
      markers: [
        introMarker,
        MediaMarker(id: 2, type: 'credits', startTimeOffset: 100000, endTimeOffset: 120000),
      ],
      (tester) async {
        await settings.write(SettingsService.skipIntroMode, SkipMarkerMode.off);
        player.emitPosition(const Duration(seconds: 110));
        await tester.pumpAndSettle();

        expect(find.byType(SkipMarkerButton), findsOneWidget);
      },
    );

    // The latch covers the button vanishing mid-press, not the chrome rising.
    // With the OSD up Back belongs to the chrome, so a press that starts under
    // a bare prompt and ends under the OSD has to be handed back.
    playerTest('the claim is released when the chrome comes up mid-press', markers: [introMarker], (tester) async {
      await showPrompt(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.gameButtonB);
      await tester.pump();
      chrome.show();
      await tester.pumpAndSettle();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.gameButtonB);
      await tester.pumpAndSettle();

      expect(screenBackDispositions, [
        PlayerBackDisposition.hideControls,
      ], reason: 'with the chrome up the press is the chrome to stage');
    });

    playerTest('a phone Back stays unconditional', markers: [introMarker], platform: TargetPlatform.android, (
      tester,
    ) async {
      await showPrompt(tester);

      await press(tester, LogicalKeyboardKey.gameButtonB);

      expect(find.byType(SkipMarkerButton), findsOneWidget, reason: 'the prompt does not own a phone Back');
      expect(screenBackDispositions, [PlayerBackDisposition.exitPlayer], reason: '#1938: mobile Back exits, always');
    });
  });

  // Android TV is the platform the report came from, and it is materially
  // different: the marker autofocuses the button, so the key is dispatched
  // from the button's node upward rather than from the surface. The forced-TV
  // override is the only way to get a non-Apple TV, since the Apple override
  // sets both isTV and isAppleTV.
  group('declining a skip prompt on Android TV', () {
    setUp(() async {
      TvDetectionService.debugSetAppleTVOverride(null);
      await TvDetectionService.getInstance(forceTv: true);
      TvDetectionService.setForceTVSync(true);
      PlatformDetector.debugSetIsDesktopOSOverride(false);
      await setNavigationEnabled(true);
    });

    playerTest(
      'Back declines the focused prompt and hands the remote back',
      markers: [MediaMarker(id: 1, type: 'intro', startTimeOffset: 10000, endTimeOffset: 45000)],
      (tester) async {
        InputModeTracker.reportNonPointerInput();
        player.emitPosition(const Duration(seconds: 15));
        await tester.pumpAndSettle();
        expect(focusLabel(), 'SkipMarkerButton', reason: 'precondition: TV autofocuses the sole affordance');

        await press(tester, LogicalKeyboardKey.gameButtonB);

        expect(find.byType(SkipMarkerButton), findsNothing);
        expect(player.state.position, const Duration(seconds: 15), reason: 'declining must not skip');
        expect(focusLabel(), 'PlayerSurface', reason: 'the vanished button must hand the remote back');
        expect(screenBackKeyDowns, 0, reason: 'the prompt answered the press');
        expect(screenBackDispositions, isEmpty);
      },
    );
  });

  group('skip intro on a television', () {
    setUp(() async {
      TvDetectionService.debugSetAppleTVOverride(true);
      PlatformDetector.debugSetIsDesktopOSOverride(false);
      await setNavigationEnabled(true);
    });

    // Selecting Skip Intro removes the focused button from the tree. The
    // remote must land back on the player surface — otherwise focus falls out
    // of the controls subtree, the screen node reclaims it, and its self-heal
    // turns the next Select into a chrome-raise, so pausing takes two presses
    // (#1890).
    playerTest(
      'Select toggles playback on the first press after skipping the intro',
      markers: [MediaMarker(id: 1, type: 'intro', startTimeOffset: 10000, endTimeOffset: 45000)],
      (tester) async {
        // A remote is non-pointer input, so the app is already in keyboard
        // mode when the marker appears — the combination that autofocuses the
        // skip button on TV.
        InputModeTracker.reportNonPointerInput();
        player.emitPosition(const Duration(seconds: 15));
        await tester.pumpAndSettle();
        expect(focusLabel(), 'SkipMarkerButton', reason: 'precondition: TV autofocuses the sole affordance');

        await press(tester, LogicalKeyboardKey.select);

        expect(player.state.position, const Duration(seconds: 45), reason: 'Select activated the skip');
        expect(focusLabel(), 'PlayerSurface', reason: 'the vanished button must hand the remote back');

        await press(tester, LogicalKeyboardKey.select);

        expect(toggles, 1, reason: 'one press must toggle playback, not merely raise the chrome');
      },
    );
  });

  group('covered by a route (#2195)', () {
    setUp(() => setNavigationEnabled(false));

    playerTest('chrome auto-hide does not pull the remote off a covering route', (tester) async {
      // Raise the chrome so hiding it later fires _claimPlayerSurfaceFocus.
      chrome.show();
      await tester.pumpAndSettle();

      // Push a covering route, standing in for the root-navigator profile
      // picker: the player route stays current on its own navigator, so only
      // isRouteChainCurrent — not the naive isCurrent — sees it is covered.
      final pickerFocus = FocusNode(debugLabel: 'CoveringPicker');
      final navigator = Navigator.of(tester.element(find.byType(PlexVideoControls)));
      unawaited(
        navigator.push(
          PageRouteBuilder<void>(
            pageBuilder: (_, _, _) => Focus(focusNode: pickerFocus, autofocus: true, child: const SizedBox.expand()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(pickerFocus.hasPrimaryFocus, isTrue, reason: 'precondition: the covering route owns the remote');

      // The chrome auto-hides on its timer while the picker covers the player;
      // before the fix this reclaimed the surface and wedged the D-pad (#2195).
      chrome.hide();
      await tester.pumpAndSettle();

      expect(pickerFocus.hasPrimaryFocus, isTrue, reason: 'a covered player must not reclaim focus');
      expect(focusLabel(), 'CoveringPicker');

      navigator.pop();
      await tester.pumpAndSettle();
      pickerFocus.dispose();
    });
  });
}

/// Minimal [Player] reporting steady playback; transport is routed to the
/// widget's `onPlayPauseRequested` callback so the test can count toggles.
class _TogglePlayer implements Player {
  Duration _position = const Duration(minutes: 5);
  final StreamController<Duration> _positionController = StreamController<Duration>.broadcast();

  /// Moves the playhead and announces it on the position stream, the way a
  /// real player drives marker detection.
  void emitPosition(Duration position) {
    _position = position;
    _positionController.add(position);
  }

  Future<void> close() => _positionController.close();

  @override
  String get playerType => 'mpv';

  @override
  PlayerState get state =>
      PlayerState(playing: true, position: _position, duration: const Duration(minutes: 45), seekable: true);

  /// A real player announces the new playhead right after a seek; marker
  /// detection (and its focus handling) rides on that event.
  @override
  Future<void> seek(Duration position) async => emitPosition(position);

  @override
  PlayerStreams get streams => PlayerStreams(
    playing: const Stream<bool>.empty(),
    completed: const Stream<bool>.empty(),
    buffering: const Stream<bool>.empty(),
    position: _positionController.stream,
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

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
