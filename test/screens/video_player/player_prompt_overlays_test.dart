import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/screens/video_player/widgets/player_prompt_overlays.dart';
import 'package:plezy/services/pip_service.dart';
import 'package:plezy/widgets/video_controls/player_chrome_controller.dart';
import 'package:provider/provider.dart';

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
}

Widget _wrapPrompt(Widget child) {
  return ChangeNotifierProvider(
    create: (_) => PlaybackStateProvider(),
    child: MaterialApp(
      home: Scaffold(body: Stack(children: [child])),
    ),
  );
}

AnimatedPositioned _promptPosition(WidgetTester tester) {
  return tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned));
}

MediaItem _episode() {
  return MediaItem(
    id: 'episode-2',
    backend: MediaBackend.plex,
    kind: MediaKind.episode,
    title: 'Episode 2',
    parentIndex: 1,
    index: 2,
  );
}
