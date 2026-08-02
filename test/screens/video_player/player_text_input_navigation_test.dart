import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/dpad_navigator.dart';
import 'package:plezy/focus/focusable_text_field.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/screens/video_player_screen.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/widgets/overlay_sheet.dart';
import 'package:plezy/widgets/video_controls/video_controls.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/media_items.dart';
import '../../test_helpers/mock_player_channels.dart';
import '../../test_helpers/prefs.dart';

/// Mirrors `VideoPlayerScreen.build`: a screen-level [Focus] that owns player
/// navigation, wrapping the screen's own [OverlaySheetHost]. Sheets therefore
/// sit *below* the navigation handler in the focus chain, which is what let a
/// Delete press inside the subtitle-search field walk the back pipeline out of
/// the player instead of correcting a character (#1741).
///
/// Booting the real screen needs a live player, so this shell reproduces the
/// layering instead. That makes the Backspace/Home cases genuine regression
/// guards — they exercise the production [classifyPlayerNavigationKey] — while
/// the sheet-dismissal cases pin the wiring contract the screen must keep:
/// resolve [OverlaySheetController] from a context *below* the host
/// (`_overlayChildKey`/`_sheetContext`), never from the State's own context.
class _PlayerShell extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode fieldFocusNode;
  final FocusNode sheetButtonFocusNode;
  final void Function(PlayerNavigationKey) onPlayerNavigation;

  const _PlayerShell({
    required this.controller,
    required this.fieldFocusNode,
    required this.sheetButtonFocusNode,
    required this.onPlayerNavigation,
  });

  @override
  State<_PlayerShell> createState() => _PlayerShellState();
}

class _PlayerShellState extends State<_PlayerShell> {
  final FocusNode _screenFocusNode = FocusNode(debugLabel: 'VideoPlayerScreen');
  final GlobalKey _overlayChildKey = GlobalKey();

  BuildContext get _sheetContext => _overlayChildKey.currentContext ?? context;

  @override
  void dispose() {
    _screenFocusNode.dispose();
    super.dispose();
  }

  void _handleScreenPlayerNavigation(PlayerNavigationKey navigationKey) {
    if (navigationKey != PlayerNavigationKey.home) {
      final sheetController = OverlaySheetController.maybeOf(_sheetContext);
      if (sheetController?.isOpen ?? false) {
        sheetController!.pop();
        return;
      }
    }
    widget.onPlayerNavigation(navigationKey);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _screenFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        final navigationKey = classifyPlayerNavigationKey(event, isAppleTV: false);
        if (navigationKey != PlayerNavigationKey.none) {
          return handlePlayerNavigationKeyAction(
            event,
            navigationKey,
            () => _handleScreenPlayerNavigation(navigationKey),
          );
        }
        if (node.hasPrimaryFocus) {
          return event.logicalKey.isNavigationKey ? KeyEventResult.handled : KeyEventResult.ignored;
        }
        return KeyEventResult.ignored;
      },
      child: OverlaySheetHost(
        canPop: false,
        onSystemBack: () => _handleScreenPlayerNavigation(PlayerNavigationKey.back),
        child: Builder(
          key: _overlayChildKey,
          builder: (sheetContext) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => OverlaySheetController.of(sheetContext).show<void>(
                  builder: (_) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FocusableTextField(
                        controller: widget.controller,
                        focusNode: widget.fieldFocusNode,
                        tvTextInputPresentation: TvTextInputPresentation.platform,
                      ),
                      TextButton(
                        focusNode: widget.sheetButtonFocusNode,
                        onPressed: () {},
                        child: const Text('Download'),
                      ),
                    ],
                  ),
                ),
                child: const Text('Search subtitles'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Harness {
  final TextEditingController controller;
  final FocusNode fieldFocusNode;
  final FocusNode sheetButtonFocusNode;
  final List<PlayerNavigationKey> navigations;

  _Harness({
    required this.controller,
    required this.fieldFocusNode,
    required this.sheetButtonFocusNode,
    required this.navigations,
  });

  bool get sheetIsOpen => find.byType(FocusableTextField).evaluate().isNotEmpty;
}

Future<_Harness> _pumpPlayerWithOpenSearchSheet(WidgetTester tester) async {
  final controller = TextEditingController();
  addTearDown(controller.dispose);
  final fieldFocusNode = FocusNode(debugLabel: 'subtitleSearchField');
  addTearDown(fieldFocusNode.dispose);
  final sheetButtonFocusNode = FocusNode(debugLabel: 'sheetButton');
  addTearDown(sheetButtonFocusNode.dispose);
  final navigations = <PlayerNavigationKey>[];

  await tester.pumpWidget(
    MaterialApp(
      home: _PlayerShell(
        controller: controller,
        fieldFocusNode: fieldFocusNode,
        sheetButtonFocusNode: sheetButtonFocusNode,
        onPlayerNavigation: navigations.add,
      ),
    ),
  );

  await tester.tap(find.text('Search subtitles'));
  await tester.pumpAndSettle();

  return _Harness(
    controller: controller,
    fieldFocusNode: fieldFocusNode,
    sheetButtonFocusNode: sheetButtonFocusNode,
    navigations: navigations,
  );
}

Future<void> _focusFieldWithText(WidgetTester tester, _Harness harness, String text, {required int caret}) async {
  await tester.tap(find.byType(TextField));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), text);
  await tester.pumpAndSettle();
  harness.controller.selection = TextSelection.collapsed(offset: caret);
  await tester.pump();
  expect(harness.fieldFocusNode.hasPrimaryFocus, isTrue);
}

Future<void> _pressKey(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(key);
  await tester.sendKeyUpEvent(key);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Backspace in the subtitle search field edits text instead of leaving the player', (tester) async {
    final harness = await _pumpPlayerWithOpenSearchSheet(tester);
    await _focusFieldWithText(tester, harness, 'star wars', caret: 5);

    await _pressKey(tester, LogicalKeyboardKey.backspace);

    expect(harness.controller.text, 'starwars');
    expect(harness.navigations, isEmpty);
    expect(harness.sheetIsOpen, isTrue);
  });

  testWidgets('Home in the subtitle search field moves the caret instead of leaving the player', (tester) async {
    final harness = await _pumpPlayerWithOpenSearchSheet(tester);
    await _focusFieldWithText(tester, harness, 'star wars', caret: 5);

    await _pressKey(tester, LogicalKeyboardKey.home);

    // Proves the unhandled event reached DefaultTextEditingShortcuts rather
    // than being consumed by the screen's navigation handler.
    expect(harness.controller.selection, const TextSelection.collapsed(offset: 0));
    expect(harness.controller.text, 'star wars');
    expect(harness.navigations, isEmpty);
    expect(harness.sheetIsOpen, isTrue);
  });

  testWidgets('Backspace on a non-text sheet control closes the sheet without leaving the player', (tester) async {
    final harness = await _pumpPlayerWithOpenSearchSheet(tester);
    harness.sheetButtonFocusNode.requestFocus();
    await tester.pumpAndSettle();

    await _pressKey(tester, LogicalKeyboardKey.backspace);

    expect(harness.sheetIsOpen, isFalse);
    expect(harness.navigations, isEmpty);
  });

  testWidgets('Backspace with no sheet open still drives player Back', (tester) async {
    final harness = await _pumpPlayerWithOpenSearchSheet(tester);
    harness.sheetButtonFocusNode.requestFocus();
    await tester.pumpAndSettle();
    await _pressKey(tester, LogicalKeyboardKey.backspace);
    expect(harness.sheetIsOpen, isFalse);

    await _pressKey(tester, LogicalKeyboardKey.backspace);

    expect(harness.navigations, [PlayerNavigationKey.back]);
  });

  testWidgets('Escape still closes an open sheet', (tester) async {
    final harness = await _pumpPlayerWithOpenSearchSheet(tester);
    await _focusFieldWithText(tester, harness, 'star wars', caret: 5);

    await _pressKey(tester, LogicalKeyboardKey.escape);

    expect(harness.sheetIsOpen, isFalse);
    expect(harness.navigations, isEmpty);
  });

  // Binds the fix to the real screen: the shell tests above cannot catch a
  // regression of `_overlayChildKey`/`_sheetContext`, because they model the
  // corrected wiring themselves. Resolving the host from the State's own
  // context (which sits ABOVE it) silently returns null, so Back skips the
  // sheet stage and runs the exit pipeline instead.
  testWidgets('the player screen resolves its own sheet host before exiting', (tester) async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();

    final nativeInitialize = Completer<bool>();
    final navigatorKey = GlobalKey<NavigatorState>();
    final sheetButtonFocusNode = FocusNode(debugLabel: 'playerSheetButton');
    addTearDown(sheetButtonFocusNode.dispose);

    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      // Never completes: the screen stays on its initialization surface, so no
      // real player is needed and the chrome is not presented — the state in
      // which a leaked Back goes straight to exitPlayer.
      methodHandler: (call) => call.method == 'initialize' ? nativeInitialize.future : Future<Object?>.value(),
      eventHandler: (_) async => null,
      testBody: () async {
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => PlaybackStateProvider(),
            child: MaterialApp(
              navigatorKey: navigatorKey,
              home: const Scaffold(body: Center(child: Text('behind the player'))),
            ),
          ),
        );

        unawaited(
          navigatorKey.currentState!.push(
            MaterialPageRoute<void>(
              builder: (_) => VideoPlayerScreen(metadata: testMediaItem(title: 'Sheet host test'), isOffline: true),
            ),
          ),
        );
        // The loading spinner animates forever, so pumpAndSettle would hang.
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(VideoPlayerScreen), findsOneWidget);

        // A context below the screen's own OverlaySheetHost.
        final sheetContext = tester.element(find.byType(CircularProgressIndicator));
        unawaited(
          OverlaySheetController.of(sheetContext).show<void>(
            builder: (_) =>
                TextButton(focusNode: sheetButtonFocusNode, onPressed: () {}, child: const Text('Sheet action')),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Sheet action'), findsOneWidget);

        sheetButtonFocusNode.requestFocus();
        await tester.pump();

        await tester.sendKeyDownEvent(LogicalKeyboardKey.backspace);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.backspace);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));

        expect(find.text('Sheet action'), findsNothing, reason: 'Back must close the sheet');
        expect(find.byType(VideoPlayerScreen), findsOneWidget, reason: 'Back must not also leave the player');

        await tester.pumpWidget(const SizedBox.shrink());
        nativeInitialize.complete(true);
        await tester.pump();
      },
    );
  });
}
