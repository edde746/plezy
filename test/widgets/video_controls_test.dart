import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/key_event_utils.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/media/media_version.dart';
import 'package:plezy/models/shader_preset.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/services/playback_subtitle_resolver.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/video_volume_controller.dart';
import 'package:plezy/widgets/video_controls/widgets/player_toast_indicator.dart';
import 'package:plezy/widgets/video_controls/desktop_video_controls.dart';
import 'package:plezy/widgets/video_controls/mobile_video_controls.dart';
import 'package:plezy/watch_together/providers/watch_together_provider.dart';
import 'package:plezy/widgets/video_controls/video_controls.dart';
import 'package:plezy/widgets/video_controls/models/track_controls_state.dart';
import 'package:plezy/widgets/video_controls/player_chrome_controller.dart';
import 'package:plezy/widgets/video_controls/painters/buffer_range_painter.dart';
import 'package:plezy/widgets/video_controls/widgets/mobile_skip_zones.dart';
import 'package:plezy/widgets/video_controls/widgets/skip_marker_button.dart';
import 'package:plezy/widgets/video_controls/widgets/sync_offset_control.dart';
import 'package:plezy/widgets/video_controls/widgets/timeline_slider.dart';
import 'package:plezy/widgets/video_controls/video_control_button.dart';
import 'package:plezy/widgets/video_controls/widgets/video_timeline_bar.dart';

import '../test_helpers/watch_together_fakes.dart';
import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';
import '../test_helpers/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('resolveShaderTogglePreset', () {
    test('turns shaders off when a shader is currently active', () {
      final result = resolveShaderTogglePreset(
        currentPreset: ShaderPreset.nvscalerDefault,
        savedPreset: ShaderPreset.nvscalerDefault,
        allPresets: ShaderPreset.allPresets,
      );

      expect(result, ShaderPreset.none);
    });

    test('restores the saved preset when shaders are currently off', () {
      final saved = ShaderPreset.artcnnPreset(ArtCNNModel.c4f16, ArtCNNVariant.neutral);
      final result = resolveShaderTogglePreset(
        currentPreset: ShaderPreset.none,
        savedPreset: saved,
        allPresets: ShaderPreset.allPresets,
      );

      expect(result, saved);
    });

    test('falls back to the first enabled preset when no shader is saved', () {
      final result = resolveShaderTogglePreset(
        currentPreset: ShaderPreset.none,
        savedPreset: ShaderPreset.none,
        allPresets: const [ShaderPreset.none, ShaderPreset.nvscalerDefault],
      );

      expect(result, ShaderPreset.nvscalerDefault);
    });
  });

  group('effectiveVersionQualityControls', () {
    test('clears switchable version and quality state during offline playback', () {
      final version = MediaVersion(id: 'v1', videoResolution: '1080');
      final audio = MediaAudioTrack(id: 1, languageCode: 'eng', selected: false);
      final subtitle = MediaSubtitleTrack(id: 2, languageCode: 'eng', selected: false, forced: false);

      final result = effectiveVersionQualityControls(
        isOfflinePlayback: true,
        availableVersions: [version],
        serverSupportsTranscoding: true,
        isTranscoding: true,
        sourceAudioTracks: [audio],
        selectedAudioStreamId: 1,
        sourceSubtitleTracks: [subtitle],
        selectedSubtitleChoice: const PlaybackSourceSubtitleChoice.source(2),
      );

      expect(result.canSwitch, isFalse);
      expect(result.availableVersions, isEmpty);
      expect(result.serverSupportsTranscoding, isFalse);
      expect(result.isTranscoding, isFalse);
      expect(result.sourceAudioTracks, isEmpty);
      expect(result.selectedAudioStreamId, isNull);
      expect(result.sourceSubtitleTracks, isEmpty);
      expect(result.selectedSubtitleChoice, isNull);
    });

    test('keeps switchable state during online playback', () {
      final version = MediaVersion(id: 'v1', videoResolution: '1080');
      final audio = MediaAudioTrack(id: 1, languageCode: 'eng', selected: false);
      final subtitle = MediaSubtitleTrack(id: 2, languageCode: 'eng', selected: false, forced: false);

      final result = effectiveVersionQualityControls(
        isOfflinePlayback: false,
        availableVersions: [version],
        serverSupportsTranscoding: true,
        isTranscoding: true,
        sourceAudioTracks: [audio],
        selectedAudioStreamId: 1,
        sourceSubtitleTracks: [subtitle],
        selectedSubtitleChoice: const PlaybackSourceSubtitleChoice.source(2),
      );

      expect(result.canSwitch, isTrue);
      expect(result.availableVersions, [version]);
      expect(result.serverSupportsTranscoding, isTrue);
      expect(result.isTranscoding, isTrue);
      expect(result.sourceAudioTracks, [audio]);
      expect(result.selectedAudioStreamId, 1);
      expect(result.sourceSubtitleTracks, [subtitle]);
      expect(result.selectedSubtitleChoice, const PlaybackSourceSubtitleChoice.source(2));
    });
  });

  group('selectableSourceSubtitleTracks', () {
    MediaSubtitleTrack sub(int id, {String? codec, String? key}) =>
        MediaSubtitleTrack(id: id, codec: codec, key: key, languageCode: 'eng', selected: false, forced: false);

    test('returns the full list unchanged when not transcoding', () {
      final tracks = [sub(1, codec: 'srt'), sub(2, codec: 'pgs'), sub(3, codec: 'weird')];
      expect(selectableSourceSubtitleTracks(tracks, isTranscoding: false, sidecarSourceIds: const {}), tracks);
    });

    test('keeps text, image and keyed tracks while transcoding', () {
      final text = sub(1, codec: 'srt');
      final image = sub(2, codec: 'pgs');
      final keyed = sub(3, codec: 'weird', key: '/library/streams/3');
      final result = selectableSourceSubtitleTracks(
        [text, image, keyed],
        isTranscoding: true,
        sidecarSourceIds: {keyed.id},
      );
      expect(result, [text, image, keyed]);
    });

    test('drops unsupported embedded codecs while transcoding', () {
      final text = sub(1, codec: 'ass');
      final unsupported = sub(2, codec: 'weird');
      final result = selectableSourceSubtitleTracks(
        [text, unsupported],
        isTranscoding: true,
        sidecarSourceIds: const {},
      );
      expect(result, [text]);
    });

    test('drops a keyed external row whose sidecar never resolved while transcoding', () {
      // The client fetches this one itself, and on a transcode an external file is never a burn
      // target - so with no sidecar built, nothing can draw it and reloading cannot help. Offering
      // it left a selection that silently showed no caption. Its codec is text, which is exactly why
      // the codec fallback must not cover keyed rows.
      final unresolved = sub(1, codec: 'srt', key: '/library/streams/1');
      final embedded = sub(2, codec: 'srt');
      final result = selectableSourceSubtitleTracks(
        [unresolved, embedded],
        isTranscoding: true,
        sidecarSourceIds: const {},
      );
      expect(result, [embedded], reason: 'the embedded row can still be burned');
    });

    test('offers a burnable embedded image track that has no sidecar of its own', () {
      // The regression this pins: a transcode burns PGS server-side, so the
      // track deliberately has no sidecar. Gating selection on a sidecar - or on
      // the backend - dropped it from the menu entirely, which is issue #1738's
      // "PGS subtitles wont appear at all while transcoding". Every backend can
      // be asked to burn, so the codec is the only thing that may exclude it.
      final image = sub(1, codec: 'pgssub');
      final result = selectableSourceSubtitleTracks([image], isTranscoding: true, sidecarSourceIds: const {});
      expect(result, [image]);
    });

    test('still offers an unresolved external file only once its sidecar exists', () {
      final resolved = sub(1, codec: 'srt', key: '/Videos/item/source/Subtitles/1/Stream.srt');
      final unresolved = sub(2, codec: 'weird', key: '/missing');

      final result = selectableSourceSubtitleTracks(
        [resolved, unresolved],
        isTranscoding: true,
        sidecarSourceIds: {resolved.id},
      );

      expect(result, [resolved], reason: 'an unresolved key with an unburnable codec has no delivery route');
    });

    test('only offers resolved file sidecars during direct play', () {
      final embedded = sub(1, codec: 'srt');
      final availableExternal = sub(2, codec: 'srt', key: '/available');
      final unavailableExternal = sub(3, codec: 'srt', key: '/missing');

      final result = selectableSourceSubtitleTracks(
        [embedded, availableExternal, unavailableExternal],
        isTranscoding: false,
        sidecarSourceIds: {availableExternal.id},
      );

      expect(result, [embedded, availableExternal]);
    });

    test('keeps Jellyfin external-delivery rows that remain embedded during direct play', () {
      final deliveryExternalEmbedded = MediaSubtitleTrack(
        id: 1,
        codec: 'srt',
        key: '/Videos/item/source/Subtitles/1/Stream.srt',
        usesExternalDelivery: true,
        selected: false,
        forced: false,
      );

      final result = selectableSourceSubtitleTracks(
        [deliveryExternalEmbedded],
        isTranscoding: false,
        sidecarSourceIds: const {},
      );

      expect(result, [deliveryExternalEmbedded]);
    });
  });

  test('findNewExternalSubtitleTrack ignores embedded and existing source rows', () {
    final embedded = MediaSubtitleTrack(id: 1, selected: false, forced: false);
    final existing = MediaSubtitleTrack(id: 2, external: true, selected: false, forced: false);
    final downloaded = MediaSubtitleTrack(id: 3, external: true, selected: false, forced: false);

    expect(findNewExternalSubtitleTrack([embedded, existing, downloaded], {1, 2}), downloaded);
  });

  test('subtitle download treats an already-selected source as applied', () {
    expect(
      subtitleDownloadApplyOutcomeFor(PlaybackSourceChangeOutcome.unchanged),
      SubtitleDownloadApplyOutcome.applied,
    );
  });

  group('shouldShowSkipMarkerButton', () {
    test('does not show before the first frame is rendered', () {
      expect(
        shouldShowSkipMarkerButton(
          hasFirstFrame: false,
          hasMarker: true,
          hasPlayNextPrompt: false,
          skipButtonDismissed: false,
          controlsVisible: true,
        ),
        isFalse,
      );
    });

    test('shows after first frame when marker is active and not dismissed', () {
      expect(
        shouldShowSkipMarkerButton(
          hasFirstFrame: true,
          hasMarker: true,
          hasPlayNextPrompt: false,
          skipButtonDismissed: false,
          controlsVisible: false,
        ),
        isTrue,
      );
    });

    test('does not show when dismissed until controls are visible again', () {
      expect(
        shouldShowSkipMarkerButton(
          hasFirstFrame: true,
          hasMarker: true,
          hasPlayNextPrompt: false,
          skipButtonDismissed: true,
          controlsVisible: false,
        ),
        isFalse,
      );
      expect(
        shouldShowSkipMarkerButton(
          hasFirstFrame: true,
          hasMarker: true,
          hasPlayNextPrompt: false,
          skipButtonDismissed: true,
          controlsVisible: true,
        ),
        isTrue,
      );
    });

    test('does not show while play next prompt is active', () {
      expect(
        shouldShowSkipMarkerButton(
          hasFirstFrame: true,
          hasMarker: true,
          hasPlayNextPrompt: true,
          skipButtonDismissed: false,
          controlsVisible: true,
        ),
        isFalse,
      );
    });
  });

  group('classifyPlayerNavigationKey', () {
    test('reserves only physical keyboard Escape for fullscreen', () {
      expect(
        classifyPlayerNavigationKey(
          _navigationKeyDown(LogicalKeyboardKey.escape, ui.KeyEventDeviceType.keyboard),
          isAppleTV: false,
        ),
        PlayerNavigationKey.physicalEscape,
      );
      expect(
        classifyPlayerNavigationKey(
          _navigationKeyDown(LogicalKeyboardKey.escape, ui.KeyEventDeviceType.gamepad),
          isAppleTV: false,
        ),
        PlayerNavigationKey.back,
      );
      expect(
        classifyPlayerNavigationKey(
          _navigationKeyDown(LogicalKeyboardKey.escape, ui.KeyEventDeviceType.directionalPad),
          isAppleTV: false,
        ),
        PlayerNavigationKey.back,
      );
    });

    test('treats tvOS keyboard Escape as semantic Back', () {
      expect(
        classifyPlayerNavigationKey(
          _navigationKeyDown(LogicalKeyboardKey.escape, ui.KeyEventDeviceType.keyboard),
          isAppleTV: true,
        ),
        PlayerNavigationKey.back,
      );
    });

    test('recognizes controller and browser Back keys', () {
      for (final key in [LogicalKeyboardKey.gameButtonB, LogicalKeyboardKey.goBack, LogicalKeyboardKey.browserBack]) {
        expect(
          classifyPlayerNavigationKey(_navigationKeyDown(key, ui.KeyEventDeviceType.gamepad), isAppleTV: false),
          PlayerNavigationKey.back,
        );
      }
    });

    test('recognizes only bare physical Backspace as player Back', () {
      final event = _navigationKeyDown(LogicalKeyboardKey.backspace, ui.KeyEventDeviceType.keyboard);

      expect(classifyPlayerNavigationKey(event, isAppleTV: false, hasModifiers: false), PlayerNavigationKey.back);
      expect(classifyPlayerNavigationKey(event, isAppleTV: false, hasModifiers: true), PlayerNavigationKey.none);
    });

    test('recognizes bare keyboard and browser Home', () {
      for (final key in [LogicalKeyboardKey.home, LogicalKeyboardKey.browserHome]) {
        expect(
          classifyPlayerNavigationKey(
            _navigationKeyDown(key, ui.KeyEventDeviceType.keyboard),
            isAppleTV: false,
            hasModifiers: false,
          ),
          PlayerNavigationKey.home,
        );
      }
    });

    test('surrenders bare Backspace to a focused text editor', () {
      final event = _navigationKeyDown(LogicalKeyboardKey.backspace, ui.KeyEventDeviceType.keyboard);

      expect(
        classifyPlayerNavigationKey(event, isAppleTV: false, hasModifiers: false, textEditingActive: true),
        PlayerNavigationKey.none,
      );
      expect(
        classifyPlayerNavigationKey(event, isAppleTV: false, hasModifiers: false, textEditingActive: false),
        PlayerNavigationKey.back,
      );
    });

    test('surrenders bare Home to a focused text editor but never browser Home', () {
      expect(
        classifyPlayerNavigationKey(
          _navigationKeyDown(LogicalKeyboardKey.home, ui.KeyEventDeviceType.keyboard),
          isAppleTV: false,
          hasModifiers: false,
          textEditingActive: true,
        ),
        PlayerNavigationKey.none,
      );
      // browserHome has no caret role, so an editor never takes it.
      expect(
        classifyPlayerNavigationKey(
          _navigationKeyDown(LogicalKeyboardKey.browserHome, ui.KeyEventDeviceType.keyboard),
          isAppleTV: false,
          hasModifiers: false,
          textEditingActive: true,
        ),
        PlayerNavigationKey.home,
      );
    });

    test('keeps simulated remote Home navigating while a text editor has focus', () {
      for (final deviceType in [ui.KeyEventDeviceType.directionalPad, ui.KeyEventDeviceType.gamepad]) {
        expect(
          classifyPlayerNavigationKey(
            _navigationKeyDown(LogicalKeyboardKey.home, deviceType),
            isAppleTV: false,
            hasModifiers: false,
            textEditingActive: true,
          ),
          PlayerNavigationKey.home,
          reason: 'a synthesized remote press has no caret to move',
        );
      }
    });
  });

  group('handlePlayerNavigationKeyAction', () {
    testWidgets('semantic Back activates once on key up', (tester) async {
      var actions = 0;

      final downResult = handlePlayerNavigationKeyAction(
        _keyDown(LogicalKeyboardKey.gameButtonB),
        PlayerNavigationKey.back,
        () => actions++,
      );
      final upResult = handlePlayerNavigationKeyAction(
        _keyUp(LogicalKeyboardKey.gameButtonB),
        PlayerNavigationKey.back,
        () => actions++,
      );

      expect(downResult, KeyEventResult.handled);
      expect(upResult, KeyEventResult.handled);
      expect(actions, 1);
      await tester.pump();
    });

    testWidgets('Backspace alias activates once on key up', (tester) async {
      var actions = 0;

      handlePlayerNavigationKeyAction(
        _keyDown(LogicalKeyboardKey.backspace),
        PlayerNavigationKey.back,
        () => actions++,
      );
      expect(BackKeyCoordinator.consumeIfHandled(), isTrue, reason: 'parallel route pop is suppressed on key down');
      handlePlayerNavigationKeyAction(_keyUp(LogicalKeyboardKey.backspace), PlayerNavigationKey.back, () => actions++);

      expect(actions, 1);
      await tester.pump();
    });
  });

  group('primePlayerNavigationFocusForEvent', () {
    testWidgets('claims loading-route focus on navigation key down', (tester) async {
      final playerFocus = FocusNode();
      final otherFocus = FocusNode();
      addTearDown(playerFocus.dispose);
      addTearDown(otherFocus.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              Focus(focusNode: playerFocus, child: const SizedBox()),
              Focus(focusNode: otherFocus, child: const SizedBox()),
            ],
          ),
        ),
      );
      otherFocus.requestFocus();
      await tester.pump();

      final primed = primePlayerNavigationFocusForEvent(
        _keyDown(LogicalKeyboardKey.gameButtonB),
        focusNode: playerFocus,
        playerReady: false,
        isCurrentRoute: true,
        isAppleTV: false,
      );
      await tester.pump();

      expect(primed, isTrue);
      expect(playerFocus.hasPrimaryFocus, isTrue);
    });

    testWidgets('does not steal focus after the player is ready', (tester) async {
      final playerFocus = FocusNode();
      final otherFocus = FocusNode();
      addTearDown(playerFocus.dispose);
      addTearDown(otherFocus.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              Focus(focusNode: playerFocus, child: const SizedBox()),
              Focus(focusNode: otherFocus, child: const SizedBox()),
            ],
          ),
        ),
      );
      otherFocus.requestFocus();
      await tester.pump();

      final primed = primePlayerNavigationFocusForEvent(
        _keyDown(LogicalKeyboardKey.gameButtonB),
        focusNode: playerFocus,
        playerReady: true,
        isCurrentRoute: true,
        isAppleTV: false,
      );
      await tester.pump();

      expect(primed, isFalse);
      expect(otherFocus.hasPrimaryFocus, isTrue);
    });

    testWidgets('does not steal focus from a route above the player', (tester) async {
      final playerFocus = FocusNode();
      final overlayFocus = FocusNode();
      addTearDown(playerFocus.dispose);
      addTearDown(overlayFocus.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              Focus(focusNode: playerFocus, child: const SizedBox()),
              Focus(focusNode: overlayFocus, child: const SizedBox()),
            ],
          ),
        ),
      );
      overlayFocus.requestFocus();
      await tester.pump();

      final primed = primePlayerNavigationFocusForEvent(
        _keyDown(LogicalKeyboardKey.gameButtonB),
        focusNode: playerFocus,
        playerReady: false,
        isCurrentRoute: false,
        isAppleTV: false,
      );
      await tester.pump();

      expect(primed, isFalse);
      expect(overlayFocus.hasPrimaryFocus, isTrue);
    });
  });

  group('PlayerNavigationCoordinator focus dispatch', () {
    PlayerNavigationCoordinator coordinatorFor(
      PlayerChromeController chromeController, {
      bool Function()? isPromptOpen,
      VoidCallback? dismissPrompt,
      bool Function()? isChromePresented,
      Future<bool> Function()? exitFullscreenIfActive,
      bool physicalEscapeExitsFullscreen = true,
      bool Function()? physicalEscapeExitsFullscreenProvider,
      bool Function()? exitPlayerBeforeChrome,
      VoidCallback? exitPlayer,
      VoidCallback? navigateHome,
      bool Function()? isActive,
    }) {
      return PlayerNavigationCoordinator(
        chromeController: chromeController,
        isPromptOpen: isPromptOpen ?? () => false,
        dismissPrompt: dismissPrompt ?? () {},
        isChromePresented: isChromePresented ?? () => chromeController.controlsPresented,
        exitFullscreenIfActive: exitFullscreenIfActive ?? () async => false,
        physicalEscapeExitsFullscreen: physicalEscapeExitsFullscreenProvider ?? () => physicalEscapeExitsFullscreen,
        exitPlayerBeforeChrome: exitPlayerBeforeChrome,
        exitPlayer: exitPlayer ?? () {},
        navigateHome: navigateHome ?? () {},
        isActive: isActive,
      );
    }

    Future<void> pumpNavigationFocus(WidgetTester tester, PlayerNavigationCoordinator coordinator) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Focus(
            autofocus: true,
            onKeyEvent: (_, event) {
              final navigationKey = classifyPlayerNavigationKey(event, isAppleTV: false);
              return handlePlayerNavigationKeyAction(event, navigationKey, () => coordinator.handle(navigationKey));
            },
            child: const SizedBox.expand(),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('one Back hides presented chrome and the next exits once after fade-out', (tester) async {
      final chromeController = PlayerChromeController();
      addTearDown(chromeController.dispose);
      var exits = 0;
      final coordinator = coordinatorFor(chromeController, exitPlayer: () => exits++);
      await pumpNavigationFocus(tester, coordinator);

      await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonB);

      expect(chromeController.controlsVisible, isFalse);
      expect(chromeController.controlsPresented, isTrue);
      expect(exits, 0);

      chromeController.markControlsHidden();
      await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonB);

      expect(exits, 1);
    });

    testWidgets('Back exits during pre-first-frame loading even when controls default visible', (tester) async {
      final chromeController = PlayerChromeController();
      addTearDown(chromeController.dispose);
      var exits = 0;
      final coordinator = coordinatorFor(chromeController, isChromePresented: () => false, exitPlayer: () => exits++);
      await pumpNavigationFocus(tester, coordinator);

      await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonB);

      expect(chromeController.controlsVisible, isTrue);
      expect(exits, 1);
    });

    testWidgets('mobile Back exits on the first press even with the chrome up (#1938)', (tester) async {
      final chromeController = PlayerChromeController();
      addTearDown(chromeController.dispose);
      var exits = 0;
      final coordinator = coordinatorFor(
        chromeController,
        exitPlayerBeforeChrome: () => true,
        exitPlayer: () => exits++,
      );
      await pumpNavigationFocus(tester, coordinator);

      await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonB);

      expect(exits, 1, reason: 'a phone back must close the player even while the controls are up');
      expect(chromeController.controlsVisible, isTrue, reason: 'no staged hide: the player leaves directly');
    });

    testWidgets('mobile Back dismisses an open prompt before exiting', (tester) async {
      final chromeController = PlayerChromeController();
      addTearDown(chromeController.dispose);
      var promptDismissals = 0;
      var exits = 0;
      final coordinator = coordinatorFor(
        chromeController,
        isPromptOpen: () => true,
        dismissPrompt: () => promptDismissals++,
        exitPlayerBeforeChrome: () => true,
        exitPlayer: () => exits++,
      );
      await pumpNavigationFocus(tester, coordinator);

      await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonB);

      expect(promptDismissals, 1, reason: 'prompts keep priority over the mobile exit policy');
      expect(exits, 0);
    });

    testWidgets('Back exits on the first press when the route opened with no chrome', (tester) async {
      final chromeController = PlayerChromeController(initiallyVisible: false);
      addTearDown(chromeController.dispose);
      var exits = 0;
      final coordinator = coordinatorFor(chromeController, exitPlayer: () => exits++);
      await pumpNavigationFocus(tester, coordinator);

      await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonB);

      expect(exits, 1, reason: 'a TV start has no chrome to hide, so back belongs to the route (#1765)');
    });

    testWidgets('physical Escape outside fullscreen hides presented chrome without exiting', (tester) async {
      final chromeController = PlayerChromeController();
      addTearDown(chromeController.dispose);
      var fullscreenChecks = 0;
      var exits = 0;
      final coordinator = coordinatorFor(
        chromeController,
        exitFullscreenIfActive: () async {
          fullscreenChecks++;
          return false;
        },
        exitPlayer: () => exits++,
      );
      await pumpNavigationFocus(tester, coordinator);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(fullscreenChecks, 1);
      expect(chromeController.controlsVisible, isFalse);
      expect(exits, 0);
    });

    testWidgets('physical Escape preserves event-time chrome presentation across fullscreen check', (tester) async {
      final chromeController = PlayerChromeController();
      addTearDown(chromeController.dispose);
      final fullscreenResult = Completer<bool>();
      var exits = 0;
      final coordinator = coordinatorFor(
        chromeController,
        exitFullscreenIfActive: () => fullscreenResult.future,
        exitPlayer: () => exits++,
      );
      await pumpNavigationFocus(tester, coordinator);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      chromeController.hide();
      chromeController.markControlsHidden();
      fullscreenResult.complete(false);
      await tester.pump();

      expect(chromeController.controlsVisible, isFalse);
      expect(chromeController.controlsPresented, isFalse);
      expect(exits, 0);
    });

    testWidgets('physical Escape exits native fullscreen before chrome', (tester) async {
      final chromeController = PlayerChromeController();
      addTearDown(chromeController.dispose);
      var exits = 0;
      final coordinator = coordinatorFor(
        chromeController,
        exitFullscreenIfActive: () async => true,
        exitPlayer: () => exits++,
      );
      await pumpNavigationFocus(tester, coordinator);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(chromeController.controlsVisible, isTrue);
      expect(exits, 0);
    });

    testWidgets('enabling player navigation makes physical Escape preserve fullscreen', (tester) async {
      final chromeController = PlayerChromeController();
      addTearDown(chromeController.dispose);
      var physicalEscapeExitsFullscreen = true;
      var fullscreenChecks = 0;
      var exits = 0;
      final coordinator = coordinatorFor(
        chromeController,
        exitFullscreenIfActive: () async {
          fullscreenChecks++;
          return true;
        },
        physicalEscapeExitsFullscreenProvider: () => physicalEscapeExitsFullscreen,
        exitPlayer: () => exits++,
      );
      physicalEscapeExitsFullscreen = false;
      await pumpNavigationFocus(tester, coordinator);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);

      expect(fullscreenChecks, 0);
      expect(chromeController.controlsVisible, isFalse);
      expect(exits, 0);
    });

    testWidgets('macOS physical Escape stages through chrome and player without leaving fullscreen', (tester) async {
      final chromeController = PlayerChromeController();
      addTearDown(chromeController.dispose);
      var fullscreenChecks = 0;
      var exits = 0;
      final coordinator = coordinatorFor(
        chromeController,
        exitFullscreenIfActive: () async {
          fullscreenChecks++;
          return true;
        },
        physicalEscapeExitsFullscreen: false,
        exitPlayer: () => exits++,
      );
      await pumpNavigationFocus(tester, coordinator);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);

      expect(fullscreenChecks, 0);
      expect(chromeController.controlsVisible, isFalse);
      expect(exits, 0);

      chromeController.markControlsHidden();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);

      expect(fullscreenChecks, 0);
      expect(exits, 1);
    });

    testWidgets('physical Escape does nothing after its player route is disposed', (tester) async {
      final chromeController = PlayerChromeController();
      addTearDown(chromeController.dispose);
      final fullscreenResult = Completer<bool>();
      var active = true;
      var exits = 0;
      final coordinator = coordinatorFor(
        chromeController,
        exitFullscreenIfActive: () => fullscreenResult.future,
        exitPlayer: () => exits++,
        isActive: () => active,
      );
      await pumpNavigationFocus(tester, coordinator);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      active = false;
      fullscreenResult.complete(false);
      await tester.pump();

      expect(chromeController.controlsVisible, isTrue);
      expect(exits, 0);
    });

    testWidgets('Back closes the content strip without hiding chrome or exiting', (tester) async {
      final chromeController = PlayerChromeController()..setContentStripVisible(true);
      addTearDown(chromeController.dispose);
      var exits = 0;
      final coordinator = coordinatorFor(chromeController, exitPlayer: () => exits++);
      await pumpNavigationFocus(tester, coordinator);

      await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonB);

      expect(chromeController.contentStripVisible, isFalse);
      expect(chromeController.controlsVisible, isTrue);
      expect(exits, 0);
      chromeController.cancelAutoHide();
    });

    testWidgets('Home bypasses staged Back layers', (tester) async {
      final chromeController = PlayerChromeController()..setContentStripVisible(true);
      addTearDown(chromeController.dispose);
      var promptOpen = true;
      var promptDismissals = 0;
      var homeNavigations = 0;
      final coordinator = coordinatorFor(
        chromeController,
        isPromptOpen: () => promptOpen,
        dismissPrompt: () {
          promptOpen = false;
          promptDismissals++;
        },
        navigateHome: () => homeNavigations++,
      );
      await pumpNavigationFocus(tester, coordinator);

      await tester.sendKeyEvent(LogicalKeyboardKey.home);

      expect(homeNavigations, 1);
      expect(promptDismissals, 0);
      expect(chromeController.contentStripVisible, isTrue);
      expect(chromeController.controlsVisible, isTrue);
    });

    testWidgets('global observation and focus dispatch produce one native Back action', (tester) async {
      final chromeController = PlayerChromeController();
      addTearDown(chromeController.dispose);
      var globalEvents = 0;
      var exits = 0;
      bool globalHandler(KeyEvent event) {
        if (classifyPlayerNavigationKey(event, isAppleTV: false) != PlayerNavigationKey.none) {
          globalEvents++;
        }
        return false;
      }

      HardwareKeyboard.instance.addHandler(globalHandler);
      addTearDown(() => HardwareKeyboard.instance.removeHandler(globalHandler));
      await pumpNavigationFocus(tester, coordinatorFor(chromeController, exitPlayer: () => exits++));

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);

      expect(globalEvents, 2);
      expect(chromeController.controlsVisible, isFalse);
      expect(exits, 0);
    });
  });

  group('resolvePlayerBackDisposition', () {
    test('closes a content strip before other Back behavior', () {
      expect(
        resolvePlayerBackDisposition(
          navigationKey: PlayerNavigationKey.physicalEscape,
          contentStripVisible: true,
          controlsVisible: true,
        ),
        PlayerBackDisposition.closeContentStrip,
      );
    });

    test('checks fullscreen only for physical Escape', () {
      expect(
        resolvePlayerBackDisposition(
          navigationKey: PlayerNavigationKey.physicalEscape,
          contentStripVisible: false,
          controlsVisible: false,
        ),
        PlayerBackDisposition.exitFullscreenIfActive,
      );
      expect(
        resolvePlayerBackDisposition(
          navigationKey: PlayerNavigationKey.back,
          contentStripVisible: false,
          controlsVisible: false,
        ),
        PlayerBackDisposition.exitPlayer,
      );
    });
  });

  group('shouldPhysicalEscapeExitFullscreen', () {
    test('uses fullscreen-first behavior for normal Windows and Linux navigation', () {
      expect(
        shouldPhysicalEscapeExitFullscreen(
          isMacOS: false,
          videoPlayerNavigationEnabled: false,
          playerEnteredFullscreen: true,
        ),
        isTrue,
      );
    });

    test('preserves fullscreen when HTPC-style player navigation is enabled', () {
      expect(
        shouldPhysicalEscapeExitFullscreen(
          isMacOS: false,
          videoPlayerNavigationEnabled: true,
          playerEnteredFullscreen: true,
        ),
        isFalse,
      );
    });

    test('preserves native fullscreen inside the macOS player', () {
      expect(
        shouldPhysicalEscapeExitFullscreen(
          isMacOS: true,
          videoPlayerNavigationEnabled: false,
          playerEnteredFullscreen: true,
        ),
        isFalse,
      );
    });

    test('preserves app-owned fullscreen the player did not enter', () {
      expect(
        shouldPhysicalEscapeExitFullscreen(
          isMacOS: false,
          videoPlayerNavigationEnabled: false,
          playerEnteredFullscreen: false,
        ),
        isFalse,
      );
    });
  });

  group('SkipMarkerButton', () {
    testWidgets('tap activates skip', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      var activateCount = 0;

      await _pumpSkipMarkerButton(
        tester,
        focusNode: focusNode,
        isAutoSkipActive: true,
        onActivate: () => activateCount++,
      );

      expect(find.text('${t.videoControls.skipIntro} (3)'), findsOneWidget);

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(activateCount, 1);
    });

    testWidgets('select activates skip', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      var activateCount = 0;

      await _pumpSkipMarkerButton(
        tester,
        focusNode: focusNode,
        isAutoSkipActive: true,
        onActivate: () => activateCount++,
      );

      focusNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pump();

      expect(activateCount, 1);
    });

    testWidgets('d-pad down moves focus without activating', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      var activateCount = 0;
      var focusDownCount = 0;

      await _pumpSkipMarkerButton(
        tester,
        focusNode: focusNode,
        isAutoSkipActive: true,
        onActivate: () => activateCount++,
        onFocusDown: () => focusDownCount++,
      );

      focusNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(activateCount, 0);
      expect(focusDownCount, 1);
    });

    testWidgets('tap activates when auto-skip is inactive', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      var activateCount = 0;

      await _pumpSkipMarkerButton(
        tester,
        focusNode: focusNode,
        isAutoSkipActive: false,
        onActivate: () => activateCount++,
      );

      expect(find.text(t.videoControls.skipIntro), findsOneWidget);

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(activateCount, 1);
    });

    testWidgets('uses the localized marker label', (tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.pt));
      addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await _pumpSkipMarkerButton(tester, focusNode: focusNode, isAutoSkipActive: false, onActivate: () {});

      expect(t.videoControls.skipIntro, 'Pular abertura');
      expect(find.text('Pular abertura'), findsOneWidget);
      expect(find.text('Skip Intro'), findsNothing);
    });
  });

  group('mobileSkipZoneForTap', () {
    const size = Size(1000, 600);

    test('returns backward for left skip zone', () {
      expect(mobileSkipZoneForTap(position: const Offset(100, 300), size: size), isFalse);
    });

    test('returns forward for right skip zone', () {
      expect(mobileSkipZoneForTap(position: const Offset(900, 300), size: size), isTrue);
    });

    test('returns null outside skip zones', () {
      expect(mobileSkipZoneForTap(position: const Offset(500, 300), size: size), isNull);
      expect(mobileSkipZoneForTap(position: const Offset(100, 20), size: size), isNull);
      expect(mobileSkipZoneForTap(position: const Offset(900, 580), size: size), isNull);
    });
  });

  group('play/pause callback routing', () {
    testWidgets('desktop button delegates without issuing a player command', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      await initializeDateFormatting('en');
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      resetSharedPreferencesForTest();
      SettingsService.resetForTesting();
      final settings = await SettingsService.getInstance();
      final player = FakeSyncPlayer();
      addTearDown(player.dispose);
      final volume = VideoVolumeController(player: player, settings: settings, initialVolume: 100);
      addTearDown(volume.dispose);
      var requests = 0;

      final watchTogether = WatchTogetherProvider();
      addTearDown(watchTogether.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<WatchTogetherProvider>.value(
          value: watchTogether,
          child: MaterialApp(
            theme: ThemeData(extensions: const [testMonoTokens]),
            home: Scaffold(
              body: SizedBox(
                width: 1000,
                height: 700,
                child: DesktopVideoControls(
                  useDpadNavigation: false,
                  player: player,
                  volumeController: volume,
                  metadata: testMediaItem(id: 'desktop'),
                  onPlayPause: () => requests++,
                  chapters: const [],
                  chaptersLoaded: true,
                  seekTimeSmall: 10,
                  onSeekToPreviousChapter: () {},
                  onSeekToNextChapter: () {},
                  onSeek: (_) {},
                  onSeekEnd: (_) {},
                  getReplayIcon: (_) => Icons.replay,
                  getForwardIcon: (_) => Icons.forward_10,
                  trackControlsState: const TrackControlsState(canControl: true),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.bySemanticsLabel(t.videoControls.playButton).last);
      await tester.pump();

      expect(requests, 1);
      expect(player.commandLog.where((entry) => entry == 'play' || entry == 'pause'), isEmpty);
    });

    testWidgets('mobile button delegates and preserves chrome timer behavior', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      await initializeDateFormatting('en');
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      resetSharedPreferencesForTest();
      SettingsService.resetForTesting();
      await SettingsService.getInstance();
      final player = FakeSyncPlayer();
      addTearDown(player.dispose);
      var requests = 0;
      var startAutoHide = 0;
      var cancelAutoHide = 0;

      final watchTogether = WatchTogetherProvider();
      addTearDown(watchTogether.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<WatchTogetherProvider>.value(
          value: watchTogether,
          child: MaterialApp(
            theme: ThemeData(extensions: const [testMonoTokens]),
            home: Scaffold(
              body: SizedBox(
                width: 500,
                height: 800,
                child: MobileVideoControls(
                  player: player,
                  metadata: testMediaItem(id: 'mobile'),
                  chapters: const [],
                  chaptersLoaded: true,
                  seekTimeSmall: 10,
                  trackChapterControls: const SizedBox.shrink(),
                  onSeek: (_) {},
                  onSeekEnd: (_) {},
                  onPlayPause: () => requests++,
                  onStartAutoHide: () => startAutoHide++,
                  onCancelAutoHide: () => cancelAutoHide++,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.bySemanticsLabel(t.videoControls.playButton).last);
      await tester.pump();

      expect(requests, 1);
      expect(startAutoHide, 1);
      expect(cancelAutoHide, 0);
      expect(player.commandLog.where((entry) => entry == 'play' || entry == 'pause'), isEmpty);
    });
  });

  group('TimelineSlider', () {
    testWidgets('routes keyboard input through the custom focus handler', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      var keyEvents = 0;
      var seekEvents = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: TimelineSlider(
                position: const Duration(minutes: 1),
                duration: const Duration(minutes: 10),
                chapters: const [],
                chaptersLoaded: true,
                focusNode: focusNode,
                onKeyEvent: (_, event) {
                  if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowRight) {
                    keyEvents++;
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                onSeek: (_) => seekEvents++,
                onSeekEnd: (_) {},
              ),
            ),
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(keyEvents, 1);
      expect(seekEvents, 0);
    });

    testWidgets('focused slider owns one adjustable semantics node', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      final semantics = tester.ensureSemantics();
      final focusNode = FocusNode(debugLabel: 'semantic_timeline');
      addTearDown(focusNode.dispose);
      final seekEnds = <Duration>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: TimelineSlider(
                position: const Duration(minutes: 1),
                duration: const Duration(minutes: 10),
                chapters: const [],
                chaptersLoaded: true,
                focusNode: focusNode,
                onSeek: (_) {},
                onSeekEnd: seekEnds.add,
              ),
            ),
          ),
        ),
      );
      focusNode.requestFocus();
      await tester.pump();

      final finder = find.bySemanticsLabel(t.videoControls.timelineSlider);
      expect(finder, findsOneWidget);
      final node = tester.getSemantics(finder);
      final data = node.getSemanticsData();
      expect(data.label, t.videoControls.timelineSlider);
      expect(data.value, '1:00');
      expect(data.increasedValue, '1:10');
      expect(data.decreasedValue, '0:50');
      expect(data.flagsCollection.isSlider, isTrue);
      expect(data.flagsCollection.isEnabled, ui.Tristate.isTrue);
      expect(data.flagsCollection.isButton, isFalse);
      expect(data.hasAction(ui.SemanticsAction.tap), isFalse);
      expect(data.hasAction(ui.SemanticsAction.increase), isTrue);
      expect(data.hasAction(ui.SemanticsAction.decrease), isTrue);

      node.owner!.performAction(node.id, ui.SemanticsAction.increase);
      node.owner!.performAction(node.id, ui.SemanticsAction.decrease);
      expect(seekEnds, const [Duration(minutes: 1, seconds: 10), Duration(seconds: 50)]);
      semantics.dispose();
    });

    testWidgets('does not pass chapters to painter when timeline markers are hidden', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: TimelineSlider(
                position: const Duration(minutes: 1),
                duration: const Duration(minutes: 10),
                chapters: [MediaChapter(id: 1, startTimeOffset: 300000)],
                chaptersLoaded: true,
                showChapterMarkersOnTimeline: false,
                onSeek: (_) {},
                onSeekEnd: (_) {},
              ),
            ),
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.byWidgetPredicate((widget) => widget is CustomPaint && widget.painter is BufferRangePainter),
      );

      expect((customPaint.painter! as BufferRangePainter).chapters, isEmpty);
    });

    testWidgets('clamps stale position beyond duration before building slider', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: TimelineSlider(
                position: const Duration(minutes: 12),
                duration: const Duration(minutes: 10),
                chapters: const [],
                chaptersLoaded: true,
                onSeek: (_) {},
                onSeekEnd: (_) {},
              ),
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));

      expect(slider.value, const Duration(minutes: 10).inMilliseconds.toDouble());
      expect(slider.max, const Duration(minutes: 10).inMilliseconds.toDouble());
    });

    testWidgets('clamps stale position when duration is unknown', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: TimelineSlider(
                position: const Duration(minutes: 12),
                duration: Duration.zero,
                chapters: const [],
                chaptersLoaded: true,
                onSeek: (_) {},
                onSeekEnd: (_) {},
              ),
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));

      expect(slider.value, 0.0);
      expect(slider.max, 0.0);
    });

    testWidgets('timeline bar displays pending preview position while player position is stale', (tester) async {
      final player = FakeSyncPlayer(position: const Duration(minutes: 1), duration: const Duration(minutes: 10));
      addTearDown(player.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: VideoTimelineBar(
                player: player,
                chapters: const [],
                chaptersLoaded: true,
                previewPosition: const Duration(minutes: 4),
                onSeek: (_) {},
                onSeekEnd: (_) {},
              ),
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, const Duration(minutes: 4).inMilliseconds.toDouble());
    });

    Future<void> pumpScrubSlider(
      WidgetTester tester, {
      required List<Duration> seeks,
      required List<Duration> seekEnds,
      Duration duration = const Duration(minutes: 10),
      bool enabled = true,
      VoidCallback? onScrubStart,
      VoidCallback? onScrubEnd,
      Widget Function(Widget child)? wrap,
    }) async {
      Widget slider = SizedBox(
        width: 400,
        child: TimelineSlider(
          position: const Duration(minutes: 1),
          duration: duration,
          chapters: const [],
          chaptersLoaded: true,
          enabled: enabled,
          onSeek: seeks.add,
          onSeekEnd: seekEnds.add,
          onScrubStart: onScrubStart,
          onScrubEnd: onScrubEnd,
        ),
      );
      if (wrap != null) slider = wrap(slider);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: slider)),
        ),
      );
    }

    testWidgets('touch drag survives tooltip appearance and finalizes once', (tester) async {
      final seeks = <Duration>[];
      final seekEnds = <Duration>[];
      var scrubStarts = 0;
      var scrubEnds = 0;
      await pumpScrubSlider(
        tester,
        seeks: seeks,
        seekEnds: seekEnds,
        onScrubStart: () => scrubStarts++,
        onScrubEnd: () => scrubEnds++,
      );

      // Down at the center (200/400 → 5min), drag +100px (→ 7.5min). The
      // first scrub event makes the tooltip appear; the drag must keep
      // tracking through that rebuild and finalize exactly once.
      final gesture = await tester.startGesture(tester.getCenter(find.byType(TimelineSlider)));
      await tester.pump();
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(seeks, isNotEmpty);
      expect(seekEnds, hasLength(1));
      expect(scrubStarts, 1);
      expect(scrubEnds, 1);
      expect(seekEnds.single.inMilliseconds, closeTo(const Duration(minutes: 7, seconds: 30).inMilliseconds, 2000));
    });

    testWidgets('keyboard input does not start a scrub lifecycle', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      var scrubStarts = 0;
      var scrubEnds = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: TimelineSlider(
                position: const Duration(minutes: 1),
                duration: const Duration(minutes: 10),
                chapters: const [],
                chaptersLoaded: true,
                focusNode: focusNode,
                onKeyEvent: (_, event) => KeyEventResult.handled,
                onSeek: (_) {},
                onSeekEnd: (_) {},
                onScrubStart: () => scrubStarts++,
                onScrubEnd: () => scrubEnds++,
              ),
            ),
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(scrubStarts, 0);
      expect(scrubEnds, 0);
    });

    testWidgets('disposing mid-drag ends the scrub lifecycle', (tester) async {
      final seeks = <Duration>[];
      final seekEnds = <Duration>[];
      var scrubStarts = 0;
      var scrubEnds = 0;
      await pumpScrubSlider(
        tester,
        seeks: seeks,
        seekEnds: seekEnds,
        onScrubStart: () => scrubStarts++,
        onScrubEnd: () => scrubEnds++,
      );

      final gesture = await tester.startGesture(tester.getCenter(find.byType(TimelineSlider)));
      await tester.pump();
      expect(scrubStarts, 1);
      expect(scrubEnds, 0);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await gesture.cancel();

      expect(scrubEnds, 1);
    });

    testWidgets('tap seeks to the tapped position', (tester) async {
      final seeks = <Duration>[];
      final seekEnds = <Duration>[];
      await pumpScrubSlider(tester, seeks: seeks, seekEnds: seekEnds);

      final topLeft = tester.getTopLeft(find.byType(TimelineSlider));
      final size = tester.getSize(find.byType(TimelineSlider));
      final gesture = await tester.startGesture(Offset(topLeft.dx + size.width * 0.75, topLeft.dy + size.height / 2));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(seekEnds, hasLength(1));
      expect(seekEnds.single.inMilliseconds, closeTo(const Duration(minutes: 7, seconds: 30).inMilliseconds, 2000));
    });

    testWidgets('drag starting on the slider is never stolen by ancestor recognizers', (tester) async {
      final seeks = <Duration>[];
      final seekEnds = <Duration>[];
      var verticalDragUpdates = 0;
      var longPresses = 0;
      await pumpScrubSlider(
        tester,
        seeks: seeks,
        seekEnds: seekEnds,
        wrap: (child) => GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragUpdate: (_) => verticalDragUpdates++,
          onLongPressStart: (_) => longPresses++,
          child: child,
        ),
      );

      // Press-aim-drag: hold past the long-press deadline, then drag with a
      // vertical-dominant start. Without the eager claim, the long-press or
      // the vertical recognizer wins and the scrub is eaten.
      final gesture = await tester.startGesture(tester.getCenter(find.byType(TimelineSlider)));
      await tester.pump(const Duration(milliseconds: 600));
      for (var i = 0; i < 4; i++) {
        await gesture.moveBy(const Offset(8, 12));
        await tester.pump();
      }
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(seekEnds, hasLength(1));
      expect(verticalDragUpdates, 0);
      expect(longPresses, 0);
    });

    testWidgets('ignores input when disabled', (tester) async {
      final seeks = <Duration>[];
      final seekEnds = <Duration>[];
      await pumpScrubSlider(tester, seeks: seeks, seekEnds: seekEnds, enabled: false);

      final gesture = await tester.startGesture(tester.getCenter(find.byType(TimelineSlider)));
      await tester.pump();
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(seeks, isEmpty);
      expect(seekEnds, isEmpty);
    });

    testWidgets('ignores input when duration is unknown', (tester) async {
      final seeks = <Duration>[];
      final seekEnds = <Duration>[];
      await pumpScrubSlider(tester, seeks: seeks, seekEnds: seekEnds, duration: Duration.zero);

      final gesture = await tester.startGesture(tester.getCenter(find.byType(TimelineSlider)));
      await tester.pump();
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(seeks, isEmpty);
      expect(seekEnds, isEmpty);
    });

    testWidgets('second finger is ignored mid-drag', (tester) async {
      final seeks = <Duration>[];
      final seekEnds = <Duration>[];
      await pumpScrubSlider(tester, seeks: seeks, seekEnds: seekEnds);

      final center = tester.getCenter(find.byType(TimelineSlider));
      final first = await tester.startGesture(center);
      await tester.pump();
      final seeksAfterDown = seeks.length;

      final second = await tester.startGesture(center + const Offset(100, 0));
      await tester.pump();
      await second.moveBy(const Offset(-80, 0));
      await tester.pump();
      expect(seeks.length, seeksAfterDown, reason: 'second pointer must not drive the scrub');

      await first.moveBy(const Offset(40, 0));
      await tester.pump();
      await first.up();
      await second.up();
      await tester.pump();

      // 240/400 of 10min → 6min: follows the first pointer only.
      expect(seekEnds, hasLength(1));
      expect(seekEnds.single.inMilliseconds, closeTo(const Duration(minutes: 6).inMilliseconds, 2000));
    });
  });

  group('shouldSkipDuplicateTimelineSeek', () {
    test('skips a matching final seek', () {
      expect(
        shouldSkipDuplicateTimelineSeek(
          lastDispatchedSeek: const Duration(minutes: 7, seconds: 30),
          finalSeek: const Duration(minutes: 7, seconds: 30),
        ),
        isTrue,
      );
    });

    test('does not skip when no matching seek was already dispatched', () {
      expect(
        shouldSkipDuplicateTimelineSeek(
          lastDispatchedSeek: const Duration(minutes: 7),
          finalSeek: const Duration(minutes: 7, seconds: 30),
        ),
        isFalse,
      );
      expect(
        shouldSkipDuplicateTimelineSeek(lastDispatchedSeek: null, finalSeek: const Duration(minutes: 7, seconds: 30)),
        isFalse,
      );
    });
  });

  group('shouldStartHiddenDirectionalSeek', () {
    test('accepts the initial press and its repeats, so a held key keeps seeking in place', () {
      expect(shouldStartHiddenDirectionalSeek(_keyDown(LogicalKeyboardKey.arrowRight)), isTrue);
      expect(
        shouldStartHiddenDirectionalSeek(
          const KeyRepeatEvent(
            physicalKey: PhysicalKeyboardKey.arrowRight,
            logicalKey: LogicalKeyboardKey.arrowRight,
            timeStamp: Duration.zero,
          ),
        ),
        isTrue,
        reason: 'hidden-chrome seeking owns the whole burst instead of escalating to the timeline',
      );
      expect(
        shouldStartHiddenDirectionalSeek(_keyUp(LogicalKeyboardKey.arrowRight)),
        isFalse,
        reason: 'release commits the burst, it does not add another step',
      );
    });
  });

  group('subtitle visibility', () {
    testWidgets('rolls back a failed latest toggle to the preceding successful mutation', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      await initializeDateFormatting('en');
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      resetSharedPreferencesForTest();
      SettingsService.resetForTesting();
      final settings = await SettingsService.getInstance();
      final firstWrite = Completer<void>();
      final secondWrite = Completer<void>();
      final player = _FakeSubtitleVisibilityPlayer(writes: [firstWrite, secondWrite]);
      final volume = VideoVolumeController(player: player, settings: settings, initialVolume: 100);
      final playbackState = PlaybackStateProvider();
      final watchTogether = WatchTogetherProvider();
      final chrome = PlayerChromeController();
      final toast = PlayerToastController();
      addTearDown(volume.dispose);
      addTearDown(playbackState.dispose);
      addTearDown(watchTogether.dispose);
      addTearDown(chrome.dispose);
      addTearDown(toast.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<PlaybackStateProvider>.value(value: playbackState),
            ChangeNotifierProvider<WatchTogetherProvider>.value(value: watchTogether),
          ],
          child: MaterialApp(
            theme: ThemeData(platform: TargetPlatform.macOS, extensions: const [testMonoTokens]),
            home: Scaffold(
              body: SizedBox(
                width: 1200,
                height: 800,
                child: PlexVideoControls(
                  player: player,
                  volumeController: volume,
                  metadata: testMediaItem(id: 'subtitle-visibility'),
                  toastController: toast,
                  canNavigateMediaItems: false,
                  chromeController: chrome,
                  isLive: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Symbols.subtitles_rounded), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.pump();
      expect(player.propertyValues, ['no']);
      expect(find.byIcon(Symbols.subtitles_off_rounded), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.pump();
      expect(player.propertyValues, ['no'], reason: 'the latest toggle must wait for the in-flight native write');
      expect(find.byIcon(Symbols.subtitles_rounded), findsOneWidget);

      firstWrite.complete();
      await tester.pump();
      await tester.pump();
      expect(player.propertyValues, ['no', 'yes']);

      secondWrite.completeError(PlatformException(code: 'SET_PROPERTY_FAILED'));
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Symbols.subtitles_off_rounded), findsOneWidget);
      chrome.cancelAutoHide();
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('SyncOffsetControl', () {
    testWidgets('uses 50ms slider steps across ±10s without rendering tick marks', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [testMonoTokens]),
          home: Scaffold(
            body: SizedBox(
              width: 700,
              child: SyncOffsetControl(
                player: _FakeSyncPlayer(),
                propertyName: 'sub-delay',
                initialOffset: 0,
                onOffsetChanged: (_) async {},
              ),
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      final sliderTheme = tester.widget<SliderTheme>(
        find.ancestor(of: find.byType(Slider), matching: find.byType(SliderTheme)).first,
      );

      expect(slider.min, -10000);
      expect(slider.max, 10000);
      expect(slider.divisions, 400);
      expect((slider.max - slider.min) / slider.divisions!, 50);
      expect(sliderTheme.data.tickMarkShape, same(SliderTickMarkShape.noTickMark));
    });

    testWidgets('reconciles a failed current write without persisting it', (tester) async {
      final propertyWrite = Completer<void>();
      final persistedOffsets = <int>[];
      final player = _FakeSyncPlayer(onSetProperty: (_, _) => propertyWrite.future);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [testMonoTokens]),
          home: Scaffold(
            body: SizedBox(
              width: 700,
              child: SyncOffsetControl(
                player: player,
                propertyName: 'sub-delay',
                initialOffset: 500,
                onOffsetChanged: (offset) async => persistedOffsets.add(offset),
              ),
            ),
          ),
        ),
      );

      tester.widget<Slider>(find.byType(Slider)).onChanged!(600);
      await tester.pump();
      tester.widget<Slider>(find.byType(Slider)).onChangeEnd!(600);
      await tester.pump();
      expect(tester.widget<Slider>(find.byType(Slider)).value, 600);
      expect(persistedOffsets, isEmpty);

      propertyWrite.completeError(PlatformException(code: 'SET_PROPERTY_FAILED'));
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(tester.widget<Slider>(find.byType(Slider)).value, 500);
      expect(persistedOffsets, isEmpty);
    });

    testWidgets('ignores stale failure and persists the latest accepted offset once', (tester) async {
      final staleWrite = Completer<void>();
      final persistedOffsets = <int>[];
      var writeCount = 0;
      final player = _FakeSyncPlayer(
        onSetProperty: (_, _) {
          writeCount++;
          return writeCount == 1 ? staleWrite.future : Future<void>.value();
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [testMonoTokens]),
          home: Scaffold(
            body: SizedBox(
              width: 700,
              child: SyncOffsetControl(
                player: player,
                propertyName: 'audio-delay',
                initialOffset: 0,
                onOffsetChanged: (offset) async => persistedOffsets.add(offset),
              ),
            ),
          ),
        ),
      );

      tester.widget<Slider>(find.byType(Slider)).onChanged!(100);
      await tester.pump();
      tester.widget<Slider>(find.byType(Slider)).onChangeEnd!(100);
      await tester.pump();

      tester.widget<Slider>(find.byType(Slider)).onChanged!(200);
      await tester.pump();
      tester.widget<Slider>(find.byType(Slider)).onChangeEnd!(200);
      await tester.pump();
      await tester.pump();
      expect(persistedOffsets, isEmpty);

      staleWrite.completeError(PlatformException(code: 'SET_PROPERTY_FAILED'));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(tester.widget<Slider>(find.byType(Slider)).value, 200);
      expect(persistedOffsets, [200]);
    });

    testWidgets('rolls back a failed latest write to the preceding successful offset', (tester) async {
      final firstWrite = Completer<void>();
      final secondWrite = Completer<void>();
      final propertyValues = <String>[];
      final persistedOffsets = <int>[];
      final player = _FakeSyncPlayer(
        onSetProperty: (_, value) {
          propertyValues.add(value);
          return propertyValues.length == 1 ? firstWrite.future : secondWrite.future;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [testMonoTokens]),
          home: Scaffold(
            body: SizedBox(
              width: 700,
              child: SyncOffsetControl(
                player: player,
                propertyName: 'sub-delay',
                initialOffset: 0,
                onOffsetChanged: (offset) async {
                  persistedOffsets.add(offset);
                },
              ),
            ),
          ),
        ),
      );

      tester.widget<Slider>(find.byType(Slider)).onChanged!(100);
      tester.widget<Slider>(find.byType(Slider)).onChangeEnd!(100);
      await tester.pump();
      expect(propertyValues, ['0.1']);

      tester.widget<Slider>(find.byType(Slider)).onChanged!(200);
      tester.widget<Slider>(find.byType(Slider)).onChangeEnd!(200);
      await tester.pump();
      expect(propertyValues, ['0.1']);
      expect(tester.widget<Slider>(find.byType(Slider)).value, 200);

      firstWrite.complete();
      await tester.pump();
      await tester.pump();
      expect(propertyValues, ['0.1', '0.2']);
      expect(persistedOffsets, [100]);

      secondWrite.completeError(PlatformException(code: 'SET_PROPERTY_FAILED'));
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(tester.widget<Slider>(find.byType(Slider)).value, 100);
      expect(persistedOffsets, [100]);
    });

    testWidgets('persists an accepted offset after the control is disposed', (tester) async {
      final propertyWrite = Completer<void>();
      final persistedOffsets = <int>[];
      final player = _FakeSyncPlayer(onSetProperty: (_, _) => propertyWrite.future);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [testMonoTokens]),
          home: Scaffold(
            body: SizedBox(
              width: 700,
              child: SyncOffsetControl(
                player: player,
                propertyName: 'sub-delay',
                initialOffset: 0,
                onOffsetChanged: (offset) async => persistedOffsets.add(offset),
              ),
            ),
          ),
        ),
      );

      tester.widget<Slider>(find.byType(Slider)).onChanged!(100);
      tester.widget<Slider>(find.byType(Slider)).onChangeEnd!(100);
      await tester.pumpWidget(const SizedBox.shrink());
      propertyWrite.complete();
      await tester.pump();

      expect(persistedOffsets, [100]);
    });

    testWidgets('step buttons move by 50ms per tap', (tester) async {
      final persistedOffsets = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [testMonoTokens]),
          home: Scaffold(
            body: SizedBox(
              width: 700,
              child: SyncOffsetControl(
                player: _FakeSyncPlayer(),
                propertyName: 'audio-delay',
                initialOffset: 0,
                onOffsetChanged: (offset) async => persistedOffsets.add(offset),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Symbols.add_rounded));
      await tester.pump();
      expect(tester.widget<Slider>(find.byType(Slider)).value, 50);

      await tester.tap(find.byIcon(Symbols.remove_rounded));
      await tester.pump();
      await tester.tap(find.byIcon(Symbols.remove_rounded));
      await tester.pump();

      expect(tester.widget<Slider>(find.byType(Slider)).value, -50);
      expect(persistedOffsets, [50, 0, -50]);
    });

    testWidgets('long-press steps by 1s per tick', (tester) async {
      final persistedOffsets = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [testMonoTokens]),
          home: Scaffold(
            body: SizedBox(
              width: 700,
              child: SyncOffsetControl(
                player: _FakeSyncPlayer(),
                propertyName: 'audio-delay',
                initialOffset: 0,
                onOffsetChanged: (offset) async => persistedOffsets.add(offset),
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(tester.getCenter(find.byIcon(Symbols.add_rounded)));
      await tester.pump(kLongPressTimeout);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      await gesture.up();
      await tester.pump();
      await tester.pump();

      expect(persistedOffsets, [1000, 2000]);
    });

    testWidgets('step buttons clamp at the ±60s absolute limit beyond the slider range', (tester) async {
      final persistedOffsets = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [testMonoTokens]),
          home: Scaffold(
            body: SizedBox(
              width: 700,
              child: SyncOffsetControl(
                player: _FakeSyncPlayer(),
                propertyName: 'sub-delay',
                initialOffset: 59980,
                onOffsetChanged: (offset) async => persistedOffsets.add(offset),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Symbols.add_rounded));
      await tester.pump();
      await tester.pump();

      expect(persistedOffsets, [60000]);
      expect(tester.widget<Slider>(find.byType(Slider)).value, 10000);
    });

    testWidgets('shows the true offset while the slider thumb clamps to its range', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [testMonoTokens]),
          home: Scaffold(
            body: SizedBox(
              width: 700,
              child: SyncOffsetControl(
                player: _FakeSyncPlayer(),
                propertyName: 'sub-delay',
                initialOffset: 45000,
                onOffsetChanged: (_) async {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('+45.0s'), findsOneWidget);
      expect(tester.widget<Slider>(find.byType(Slider)).value, 10000);
    });
  });

  group('VideoControlButton semantics', () {
    testWidgets('exposes one operable node with value and checked state', (tester) async {
      final semantics = tester.ensureSemantics();
      final focusNode = FocusNode(debugLabel: 'semantic_video_control');
      addTearDown(focusNode.dispose);
      var activations = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoControlButton(
              icon: Icons.settings,
              tooltip: 'Player settings',
              semanticValue: '720p',
              checked: true,
              focusNode: focusNode,
              onPressed: () => activations++,
            ),
          ),
        ),
      );

      final finder = find.bySemanticsLabel('Player settings');
      expect(finder, findsOneWidget);
      final data = tester.getSemantics(finder).getSemanticsData();
      expect(data.value, '720p');
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isChecked, ui.CheckedState.isTrue);
      expect(data.hasAction(ui.SemanticsAction.tap), isTrue);

      final node = tester.getSemantics(finder);
      node.owner!.performAction(node.id, ui.SemanticsAction.tap);
      await tester.pump();
      expect(activations, 1);
      semantics.dispose();
    });

    testWidgets('keeps disabled controls discoverable without a tap action', (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VideoControlButton(icon: Icons.skip_next, semanticLabel: 'Next item', onPressed: null),
          ),
        ),
      );

      final data = tester.getSemantics(find.bySemanticsLabel('Next item')).getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isEnabled, ui.Tristate.isFalse);
      expect(data.hasAction(ui.SemanticsAction.tap), isFalse);
      semantics.dispose();
    });
  });
}

KeyDownEvent _keyDown(LogicalKeyboardKey key) {
  return KeyDownEvent(physicalKey: PhysicalKeyboardKey.escape, logicalKey: key, timeStamp: Duration.zero);
}

KeyUpEvent _keyUp(LogicalKeyboardKey key) {
  return KeyUpEvent(physicalKey: PhysicalKeyboardKey.escape, logicalKey: key, timeStamp: Duration.zero);
}

KeyDownEvent _navigationKeyDown(LogicalKeyboardKey key, ui.KeyEventDeviceType deviceType) {
  return KeyDownEvent(
    physicalKey: PhysicalKeyboardKey.escape,
    logicalKey: key,
    timeStamp: Duration.zero,
    deviceType: deviceType,
  );
}

Future<void> _pumpSkipMarkerButton(
  WidgetTester tester, {
  required FocusNode focusNode,
  required bool isAutoSkipActive,
  required VoidCallback onActivate,
  VoidCallback? onFocusDown,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: const [testMonoTokens]),
      home: Scaffold(
        body: Center(
          child: SkipMarkerButton(
            marker: MediaMarker(id: 1, type: 'intro', startTimeOffset: 10000, endTimeOffset: 45000),
            playerDuration: const Duration(minutes: 20),
            hasNextEpisode: false,
            isAutoSkipActive: isAutoSkipActive,
            shouldShowAutoSkip: true,
            autoSkipDelay: 5,
            autoSkipProgress: 0.4,
            focusNode: focusNode,
            onActivate: onActivate,
            onFocusDown: onFocusDown ?? () {},
          ),
        ),
      ),
    ),
  );
}

class _FakeSyncPlayer implements Player {
  _FakeSyncPlayer({this.onSetProperty});

  final Future<void> Function(String name, String value)? onSetProperty;

  @override
  PlayerState get state => PlayerState();

  @override
  Future<void> setProperty(String name, String value) {
    return onSetProperty?.call(name, value) ?? Future<void>.value();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSubtitleVisibilityPlayer implements Player {
  _FakeSubtitleVisibilityPlayer({required this.writes});

  final List<Completer<void>> writes;
  final List<String> propertyValues = [];

  @override
  String get playerType => 'mpv';

  @override
  PlayerState get state => PlayerState(
    duration: const Duration(minutes: 45),
    seekable: true,
    tracks: const Tracks(
      subtitle: [SubtitleTrack(id: 'subtitle-1', language: 'eng')],
    ),
    track: const TrackSelection(
      subtitle: SubtitleTrack(id: 'subtitle-1', language: 'eng'),
    ),
  );

  @override
  PlayerStreams get streams => PlayerStreams(
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

  @override
  Future<void> setProperty(String name, String value) {
    expect(name, 'sub-visibility');
    propertyValues.add(value);
    return writes[propertyValues.length - 1].future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
