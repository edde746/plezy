import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/screens/video_player_screen.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/focus/focusable_button.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/media_items.dart';
import '../../test_helpers/mock_player_channels.dart';
import '../../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  testWidgets('initialization ownership serializes rollback, retry, and route removal', (tester) async {
    final failedDispose = Completer<void>();
    final replacementInitialize = Completer<bool>();
    final calls = <MethodCall>[];
    final eventCalls = <MethodCall>[];
    var initializeCount = 0;

    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) {
        calls.add(call);
        switch (call.method) {
          case 'initialize':
            initializeCount++;
            if (initializeCount == 2) return replacementInitialize.future;
            return Future<Object?>.value(true);
          case 'observeProperty':
            if (initializeCount == 1) {
              throw PlatformException(code: 'post_creation_failure', message: 'forced observation failure');
            }
            return Future<Object?>.value(null);
          case 'dispose':
            if (initializeCount == 1) return failedDispose.future;
            return Future<Object?>.value(null);
          default:
            return Future<Object?>.value(null);
        }
      },
      eventHandler: (call) async {
        eventCalls.add(call);
        return null;
      },
      testBody: () async {
        final key = GlobalKey<VideoPlayerScreenState>();
        await tester.pumpWidget(_screen(key));
        await _pumpUntil(tester, () => calls.any((call) => call.method == 'dispose'));

        expect(key.currentState?.player, isNull);
        expect(find.widgetWithText(FilledButton, 'Retry'), findsNothing);
        expect(initializeCount, 1);
        expect(eventCalls.where((call) => call.method == 'cancel'), hasLength(1));

        failedDispose.complete();
        await _pumpUntil(tester, () => find.widgetWithText(FilledButton, 'Retry').evaluate().isNotEmpty);

        final retryButton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Retry'));
        final retryFocusable = tester.widget<FocusableButton>(
          find.ancestor(of: find.widgetWithText(FilledButton, 'Retry'), matching: find.byType(FocusableButton)),
        );
        retryButton.onPressed!();
        retryFocusable.onPressed!();
        await _pumpUntil(tester, () => initializeCount == 2);

        expect(initializeCount, 2);
        expect(key.currentState?.player, isNull);
        expect(calls.where((call) => call.method == 'dispose'), hasLength(1));
        expect(eventCalls.where((call) => call.method == 'cancel'), hasLength(1));

        await tester.pumpWidget(const SizedBox.shrink());
        replacementInitialize.completeError(PlatformException(code: 'late_failure', message: 'forced late failure'));
        await _pumpUntil(tester, () => calls.where((call) => call.method == 'dispose').length == 2);

        expect(find.widgetWithText(FilledButton, 'Retry'), findsNothing);
        expect(initializeCount, 2);
        expect(calls.where((call) => call.method == 'dispose'), hasLength(2));
        expect(eventCalls.where((call) => call.method == 'cancel'), hasLength(2));
      },
    );
  });
}

Widget _screen(GlobalKey<VideoPlayerScreenState> key) {
  return ChangeNotifierProvider(
    create: (_) => PlaybackStateProvider(),
    child: MaterialApp(
      home: VideoPlayerScreen(
        key: key,
        metadata: testMediaItem(title: 'Lifecycle test video'),
        isOffline: true,
      ),
    ),
  );
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var i = 0; i < 200 && !condition(); i++) {
    await tester.pump(const Duration(milliseconds: 10));
    if (!condition()) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    }
  }
  expect(condition(), isTrue);
}
