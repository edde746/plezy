import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mixins/refreshable.dart';
import 'package:plezy/navigation/page_refresh_shortcut.dart';
import 'package:plezy/utils/platform_detector.dart';

class _ManualRefreshTarget with ManualRefreshable {
  int refreshes = 0;

  @override
  void manualRefresh() => refreshes++;
}

LogicalKeyboardKey _platformModifier() =>
    defaultTargetPlatform == TargetPlatform.macOS ? LogicalKeyboardKey.metaLeft : LogicalKeyboardKey.controlLeft;

LogicalKeyboardKey _wrongModifier() =>
    defaultTargetPlatform == TargetPlatform.macOS ? LogicalKeyboardKey.controlLeft : LogicalKeyboardKey.metaLeft;

Future<bool> _sendChord(
  WidgetTester tester,
  LogicalKeyboardKey modifier, {
  LogicalKeyboardKey? extraModifier,
  bool repeat = false,
}) async {
  await tester.sendKeyDownEvent(modifier);
  if (extraModifier != null) await tester.sendKeyDownEvent(extraModifier);
  final handled = await tester.sendKeyDownEvent(LogicalKeyboardKey.keyR);
  if (repeat) await tester.sendKeyRepeatEvent(LogicalKeyboardKey.keyR);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.keyR);
  if (extraModifier != null) await tester.sendKeyUpEvent(extraModifier);
  await tester.sendKeyUpEvent(modifier);
  await tester.pump();
  return handled;
}

Future<void> _pumpHandler(WidgetTester tester, KeyEventResult Function(KeyEvent event) handler) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Focus(autofocus: true, onKeyEvent: (_, event) => handler(event), child: const SizedBox.expand()),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    PlatformDetector.debugSetIsDesktopOSOverride(true);
    TvDetectionService.debugSetAppleTVOverride(false);
  });

  tearDown(() {
    PlatformDetector.debugSetIsDesktopOSOverride(null);
    TvDetectionService.debugSetAppleTVOverride(null);
  });

  testWidgets('the exact platform chord invokes once and key repeat does not refresh again', (tester) async {
    var refreshes = 0;
    await _pumpHandler(tester, (event) => handlePageRefreshShortcut(event, () => refreshes++));

    expect(await _sendChord(tester, _platformModifier(), repeat: true), isTrue);
    expect(refreshes, 1);
  }, variant: TargetPlatformVariant.desktop());

  testWidgets('bare R, the wrong modifier, and extra Shift or Alt do not refresh', (tester) async {
    var refreshes = 0;
    await _pumpHandler(tester, (event) => handlePageRefreshShortcut(event, () => refreshes++));

    await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
    await _sendChord(tester, _wrongModifier());
    await _sendChord(tester, _platformModifier(), extraModifier: LogicalKeyboardKey.shiftLeft);
    await _sendChord(tester, _platformModifier(), extraModifier: LogicalKeyboardKey.altLeft);

    expect(refreshes, 0);
  }, variant: TargetPlatformVariant.desktop());

  testWidgets('non-desktop and TV modes ignore the platform chord', (tester) async {
    var refreshes = 0;
    await _pumpHandler(tester, (event) => handlePageRefreshShortcut(event, () => refreshes++));

    PlatformDetector.debugSetIsDesktopOSOverride(false);
    await _sendChord(tester, _platformModifier());

    PlatformDetector.debugSetIsDesktopOSOverride(true);
    TvDetectionService.debugSetAppleTVOverride(true);
    await _sendChord(tester, _platformModifier());

    expect(refreshes, 0);
  }, variant: TargetPlatformVariant.desktop());

  testWidgets('a refresh-capable current screen is dispatched and a non-refreshable screen is ignored', (tester) async {
    final target = _ManualRefreshTarget();
    Object? currentScreen = target;
    await _pumpHandler(tester, (event) => dispatchPageRefreshShortcut(event, currentScreen));

    expect(await _sendChord(tester, _platformModifier()), isTrue);
    expect(target.refreshes, 1);

    currentScreen = Object();
    expect(await _sendChord(tester, _platformModifier()), isFalse);
    expect(target.refreshes, 1);
  }, variant: TargetPlatformVariant.desktop());

  testWidgets('a missing page callback leaves the refresh chord unhandled', (tester) async {
    await _pumpHandler(tester, (event) => handlePageRefreshShortcut(event, null));

    expect(await _sendChord(tester, _platformModifier()), isFalse);
  }, variant: TargetPlatformVariant.desktop());
}
