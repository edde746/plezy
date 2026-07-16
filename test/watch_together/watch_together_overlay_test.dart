import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/watch_together/models/watch_session.dart';
import 'package:plezy/watch_together/providers/watch_together_provider.dart';
import 'package:plezy/watch_together/widgets/watch_together_overlay.dart';
import 'package:plezy/widgets/overlay_sheet.dart';
import 'package:provider/provider.dart';

void main() {
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  for (final isHost in [false, true]) {
    final role = isHost ? 'host' : 'guest';

    testWidgets('$role confirmation survives the session sheet closing', (tester) async {
      final harness = _OverlayHarness(isHost: isHost);
      addTearDown(harness.dispose);
      await tester.pumpWidget(harness.build());

      await _openLeaveConfirmation(tester, harness);
      harness.sheetController.close();
      await tester.pumpAndSettle();

      expect(find.text(t.watchTogether.title), findsNothing);
      expect(
        find.text(isHost ? t.watchTogether.endSessionQuestion : t.watchTogether.leaveSessionQuestion),
        findsOneWidget,
      );

      await tester.tap(find.text(isHost ? t.watchTogether.endSession : t.watchTogether.leave));
      await tester.pumpAndSettle();

      expect(harness.provider.leaveCalls, 1);
      expect(harness.onLeaveSessionCalls, 1);
    });

    testWidgets('$role cancellation remains a no-op after the session sheet closes', (tester) async {
      final harness = _OverlayHarness(isHost: isHost);
      addTearDown(harness.dispose);
      await tester.pumpWidget(harness.build());

      await _openLeaveConfirmation(tester, harness);
      harness.sheetController.close();
      await tester.pumpAndSettle();

      expect(
        find.text(isHost ? t.watchTogether.endSessionQuestion : t.watchTogether.leaveSessionQuestion),
        findsOneWidget,
      );
      await tester.tap(find.text(t.common.cancel));
      await tester.pumpAndSettle();

      expect(harness.provider.leaveCalls, 0);
      expect(harness.onLeaveSessionCalls, 0);
    });
  }
}

Future<void> _openLeaveConfirmation(WidgetTester tester, _OverlayHarness harness) async {
  await tester.tap(find.byKey(_OverlayHarness.indicatorKey));
  await tester.pumpAndSettle();

  expect(harness.sheetController.isOpen, isTrue);
  await tester.tap(find.text(harness.provider.isHost ? t.watchTogether.endSession : t.watchTogether.leaveSession));
  await tester.pumpAndSettle();

  expect(find.byType(AlertDialog), findsOneWidget);
}

class _OverlayHarness {
  _OverlayHarness({required bool isHost}) : provider = _FakeWatchTogetherProvider(isHostValue: isHost);

  static const indicatorKey = Key('watch-together-session-indicator');

  final _FakeWatchTogetherProvider provider;
  late OverlaySheetController sheetController;
  int onLeaveSessionCalls = 0;

  Widget build() {
    return ChangeNotifierProvider<WatchTogetherProvider>.value(
      value: provider,
      child: MaterialApp(
        home: OverlaySheetHost(
          child: Builder(
            builder: (context) {
              sheetController = OverlaySheetController.of(context);
              return Scaffold(
                body: Center(
                  child: WatchTogetherSessionIndicator(key: indicatorKey, onLeaveSession: () => onLeaveSessionCalls++),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void dispose() => provider.dispose();
}

class _FakeWatchTogetherProvider extends WatchTogetherProvider {
  _FakeWatchTogetherProvider({required this.isHostValue});

  final bool isHostValue;
  var leaveCalls = 0;
  var _isDisposing = false;

  @override
  bool get isHost => isHostValue;

  @override
  String? get sessionId => 'ROOM42';

  @override
  ControlMode get controlMode => ControlMode.hostOnly;

  @override
  List<Participant> get participants => [
    Participant(peerId: 'local', displayName: 'Local viewer', isHost: isHostValue),
  ];

  @override
  int get participantCount => participants.length;

  @override
  Future<void> leaveSession() async {
    if (!_isDisposing) leaveCalls++;
  }

  @override
  void dispose() {
    _isDisposing = true;
    super.dispose();
  }
}
