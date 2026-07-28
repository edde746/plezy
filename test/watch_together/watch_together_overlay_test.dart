import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsNode;
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

  testWidgets('best-effort leave failure is handled by the overlay', (tester) async {
    final harness = _OverlayHarness(isHost: false, leaveError: StateError('release failed'));
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.build());

    await _openLeaveConfirmation(tester, harness);
    await tester.tap(find.text(t.watchTogether.leave));
    await tester.pumpAndSettle();

    expect(harness.provider.leaveCalls, 1);
    expect(harness.onLeaveSessionCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('session controls announce live state and the copyable room code', (tester) async {
    final semantics = tester.ensureSemantics();
    final harness = _OverlayHarness(isHost: false);
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.build());

    var finder = find.bySemanticsLabel(t.watchTogether.openSessionControls);
    expect(finder, findsOneWidget);
    var data = tester.getSemantics(finder).getSemanticsData();
    expect(data.value, '${t.watchTogether.participants}: 1');
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.flagsCollection.isEnabled, Tristate.isTrue);
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(_semanticTapNodeCount(tester), 1);

    harness.provider.updateStatus(isHost: true, isSyncing: true);
    await tester.pump();

    finder = find.bySemanticsLabel(t.watchTogether.openSessionControls);
    data = tester.getSemantics(finder).getSemanticsData();
    expect(
      data.value,
      ['${t.watchTogether.participants}: 1', t.watchTogether.youAreHost, t.watchTogether.syncing].join(', '),
    );

    await tester.tap(find.byKey(_OverlayHarness.indicatorKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final codeFinder = find.bySemanticsLabel(t.watchTogether.copySessionCode);
    expect(codeFinder, findsOneWidget);
    data = tester.getSemantics(codeFinder).getSemanticsData();
    expect(data.value, 'ROOM42');
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.flagsCollection.isEnabled, Tristate.isTrue);
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(find.bySemanticsLabel('ROOM42'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    semantics.dispose();
  });
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
  _OverlayHarness({required bool isHost, Object? leaveError})
    : provider = _FakeWatchTogetherProvider(isHostValue: isHost, leaveError: leaveError);

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
  _FakeWatchTogetherProvider({required this.isHostValue, this.leaveError});

  bool isHostValue;
  bool isSyncingValue = false;
  final Object? leaveError;
  var leaveCalls = 0;
  var _isDisposing = false;

  @override
  bool get isHost => isHostValue;

  @override
  bool get isSyncing => isSyncingValue;

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

  void updateStatus({required bool isHost, required bool isSyncing}) {
    isHostValue = isHost;
    isSyncingValue = isSyncing;
    notifyListeners();
  }

  @override
  Future<void> leaveSession() async {
    if (!_isDisposing) leaveCalls++;
    final error = leaveError;
    if (error != null) throw error;
  }

  @override
  void dispose() {
    _isDisposing = true;
    super.dispose();
  }
}

int _semanticTapNodeCount(WidgetTester tester) {
  var count = 0;
  void visit(SemanticsNode node) {
    if (node.getSemanticsData().hasAction(SemanticsAction.tap)) count++;
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(tester.binding.renderViews.single.owner!.semanticsOwner!.rootSemanticsNode!);
  return count;
}
