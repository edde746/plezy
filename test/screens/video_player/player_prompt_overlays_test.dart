import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/screens/video_player/widgets/player_prompt_overlays.dart';
import 'package:plezy/services/pip_service.dart';
import 'package:plezy/widgets/video_controls/player_chrome_controller.dart';
import 'package:provider/provider.dart';
import '../../test_helpers/media_items.dart';

void main() {
  testWidgets('play next prompt tracks chrome visibility for vertical position', (tester) async {
    PipService().isPipActive.value = false;
    final chromeController = PlayerChromeController();
    final cancelFocusNode = FocusNode(debugLabel: 'TestCancel');
    final confirmFocusNode = FocusNode(debugLabel: 'TestConfirm');
    addTearDown(chromeController.dispose);
    addTearDown(cancelFocusNode.dispose);
    addTearDown(confirmFocusNode.dispose);

    await tester.pumpWidget(
      _wrapPrompt(
        VideoPlayerPlayNextOverlay(
          visible: true,
          nextEpisode: _episode(),
          autoPlayCountdown: -1,
          cancelFocusNode: cancelFocusNode,
          confirmFocusNode: confirmFocusNode,
          chromeController: chromeController,
          onCancel: () {},
          onPlayNext: () {},
        ),
      ),
    );

    expect(_promptPosition(tester).bottom, 100);

    chromeController.hide();
    await tester.pump();
    expect(_promptPosition(tester).bottom, 24);
  });

  testWidgets('hovering play next prompt holds chrome visible and stable', (tester) async {
    PipService().isPipActive.value = false;
    final chromeController = PlayerChromeController();
    final cancelFocusNode = FocusNode(debugLabel: 'TestCancel');
    final confirmFocusNode = FocusNode(debugLabel: 'TestConfirm');
    addTearDown(chromeController.dispose);
    addTearDown(cancelFocusNode.dispose);
    addTearDown(confirmFocusNode.dispose);

    chromeController.hide();

    await tester.pumpWidget(
      _wrapPrompt(
        VideoPlayerPlayNextOverlay(
          visible: true,
          nextEpisode: _episode(),
          autoPlayCountdown: -1,
          cancelFocusNode: cancelFocusNode,
          confirmFocusNode: confirmFocusNode,
          chromeController: chromeController,
          onCancel: () {},
          onPlayNext: () {},
        ),
      ),
    );

    expect(_promptPosition(tester).bottom, 24);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: tester.getCenter(find.text('Cancel')));
    await tester.pump();

    expect(chromeController.controlsVisible, isTrue);
    expect(chromeController.isHeld(PlayerChromeHold.promptInteraction), isTrue);
    expect(_promptPosition(tester).bottom, 100);
    expect(chromeController.hide(), isFalse);
    expect(_promptPosition(tester).bottom, 100);
  });

  testWidgets('focused play next prompt holds chrome visible', (tester) async {
    PipService().isPipActive.value = false;
    final chromeController = PlayerChromeController();
    final cancelFocusNode = FocusNode(debugLabel: 'TestCancel');
    final confirmFocusNode = FocusNode(debugLabel: 'TestConfirm');
    addTearDown(chromeController.dispose);
    addTearDown(cancelFocusNode.dispose);
    addTearDown(confirmFocusNode.dispose);

    await tester.pumpWidget(
      _wrapPrompt(
        VideoPlayerPlayNextOverlay(
          visible: true,
          nextEpisode: _episode(),
          autoPlayCountdown: -1,
          cancelFocusNode: cancelFocusNode,
          confirmFocusNode: confirmFocusNode,
          chromeController: chromeController,
          onCancel: () {},
          onPlayNext: () {},
        ),
      ),
    );

    confirmFocusNode.requestFocus();
    await tester.pump();

    expect(chromeController.isHeld(PlayerChromeHold.promptInteraction), isTrue);
    expect(chromeController.hide(), isFalse);
  });

  testWidgets('removing a held prompt releases hold without notifying during dispose', (tester) async {
    PipService().isPipActive.value = false;
    final chromeController = PlayerChromeController();
    final cancelFocusNode = FocusNode(debugLabel: 'TestCancel');
    final confirmFocusNode = FocusNode(debugLabel: 'TestConfirm');
    addTearDown(chromeController.dispose);
    addTearDown(cancelFocusNode.dispose);
    addTearDown(confirmFocusNode.dispose);

    await tester.pumpWidget(
      _wrapPrompt(
        VideoPlayerPlayNextOverlay(
          visible: true,
          nextEpisode: _episode(),
          autoPlayCountdown: -1,
          cancelFocusNode: cancelFocusNode,
          confirmFocusNode: confirmFocusNode,
          chromeController: chromeController,
          onCancel: () {},
          onPlayNext: () {},
        ),
      ),
    );

    chromeController.hold(PlayerChromeHold.promptInteraction);
    var notifications = 0;
    chromeController.addListener(() => notifications++);

    await tester.pumpWidget(_wrapPrompt(const SizedBox.shrink()));

    expect(chromeController.isHeld(PlayerChromeHold.promptInteraction), isFalse);
    expect(notifications, 0);
  });

  testWidgets('the buffering spinner announces loading until the first frame renders', (tester) async {
    PipService().isPipActive.value = false;
    final isBuffering = ValueNotifier<bool>(false);
    final hasFirstFrame = ValueNotifier<bool>(false);
    final isExiting = ValueNotifier<bool>(false);
    addTearDown(isBuffering.dispose);
    addTearDown(hasFirstFrame.dispose);
    addTearDown(isExiting.dispose);
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _wrapPrompt(
        VideoPlayerBufferingOverlay(isBuffering: isBuffering, hasFirstFrame: hasFirstFrame, isExiting: isExiting),
      ),
    );

    // The TV player no longer raises its chrome on startup (#1765), so this
    // label is what tells "the player is still waiting for its first frame"
    // apart from "it has stopped waiting" — the readiness gate the Maestro TV
    // flows use in place of the Pause button.
    expect(find.bySemanticsLabel('Loading video'), findsOneWidget);

    hasFirstFrame.value = true;
    await tester.pump();
    expect(find.bySemanticsLabel('Loading video'), findsNothing);

    isBuffering.value = true;
    await tester.pump();
    expect(find.bySemanticsLabel('Loading video'), findsOneWidget, reason: 'a mid-playback stall loads again');

    semantics.dispose();
  });

  testWidgets('play next overlay renders countdown text when countdown is active', (tester) async {
    PipService().isPipActive.value = false;
    final chromeController = PlayerChromeController();
    final cancelFocusNode = FocusNode(debugLabel: 'TestCancel');
    final confirmFocusNode = FocusNode(debugLabel: 'TestConfirm');
    addTearDown(chromeController.dispose);
    addTearDown(cancelFocusNode.dispose);
    addTearDown(confirmFocusNode.dispose);

    var playNextTapped = false;
    var cancelTapped = false;

    await tester.pumpWidget(
      _wrapPrompt(
        VideoPlayerPlayNextOverlay(
          visible: true,
          nextEpisode: _episode(),
          autoPlayCountdown: 5,
          cancelFocusNode: cancelFocusNode,
          confirmFocusNode: confirmFocusNode,
          chromeController: chromeController,
          onCancel: () => cancelTapped = true,
          onPlayNext: () => playNextTapped = true,
        ),
      ),
    );

    expect(find.text('5'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    await tester.tap(find.text('5'));
    expect(playNextTapped, isTrue);

    await tester.tap(find.text('Cancel'));
    expect(cancelTapped, isTrue);
  });

  testWidgets('play next overlay renders Play Next label when countdown is disabled', (tester) async {
    PipService().isPipActive.value = false;
    final chromeController = PlayerChromeController();
    final cancelFocusNode = FocusNode(debugLabel: 'TestCancel');
    final confirmFocusNode = FocusNode(debugLabel: 'TestConfirm');
    addTearDown(chromeController.dispose);
    addTearDown(cancelFocusNode.dispose);
    addTearDown(confirmFocusNode.dispose);

    var playNextTapped = false;

    await tester.pumpWidget(
      _wrapPrompt(
        VideoPlayerPlayNextOverlay(
          visible: true,
          nextEpisode: _episode(),
          autoPlayCountdown: 0,
          cancelFocusNode: cancelFocusNode,
          confirmFocusNode: confirmFocusNode,
          chromeController: chromeController,
          onCancel: () {},
          onPlayNext: () => playNextTapped = true,
        ),
      ),
    );

    expect(find.text('Play Next'), findsOneWidget);
    await tester.tap(find.text('Play Next'));
    expect(playNextTapped, isTrue);
  });

  testWidgets('still watching overlay renders and triggers callbacks', (tester) async {
    PipService().isPipActive.value = false;
    final chromeController = PlayerChromeController();
    final pauseFocusNode = FocusNode(debugLabel: 'TestPause');
    final continueFocusNode = FocusNode(debugLabel: 'TestContinue');
    addTearDown(chromeController.dispose);
    addTearDown(pauseFocusNode.dispose);
    addTearDown(continueFocusNode.dispose);

    var pauseTapped = false;
    var continueTapped = false;

    await tester.pumpWidget(
      _wrapPrompt(
        VideoPlayerStillWatchingOverlay(
          visible: true,
          countdown: 25,
          pauseFocusNode: pauseFocusNode,
          continueFocusNode: continueFocusNode,
          chromeController: chromeController,
          onPause: () => pauseTapped = true,
          onContinue: () => continueTapped = true,
        ),
      ),
    );

    expect(find.text('Still watching?'), findsOneWidget);
    expect(find.text('Pausing in 25s'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    expect(continueTapped, isTrue);

    await tester.tap(find.text('Pause'));
    expect(pauseTapped, isTrue);
  });
}

Widget _wrapPrompt(Widget child) {
  return TranslationProvider(
    child: ChangeNotifierProvider(
      create: (_) => PlaybackStateProvider(),
      child: MaterialApp(
        home: Scaffold(body: Stack(children: [child])),
      ),
    ),
  );
}

AnimatedPositioned _promptPosition(WidgetTester tester) {
  return tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned));
}

MediaItem _episode() {
  return testMediaItem(
    id: 'episode-2',
    backend: MediaBackend.plex,
    kind: MediaKind.episode,
    title: 'Episode 2',
    parentIndex: 1,
    index: 2,
  );
}
