import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/watch_together/models/watch_session.dart';
import 'package:plezy/watch_together/providers/watch_together_provider.dart';
import 'package:plezy/watch_together/screens/watch_together_screen.dart';
import 'package:provider/provider.dart';

void main() {
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  Future<_FakeWatchTogetherProvider> pumpHostedSession(WidgetTester tester, {required String sessionId}) async {
    final provider = _FakeWatchTogetherProvider(sessionId: sessionId);
    addTearDown(provider.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<WatchTogetherProvider>.value(
        value: provider,
        child: const MaterialApp(home: WatchTogetherScreen()),
      ),
    );
    await tester.pump();
    return provider;
  }

  testWidgets('the session code is the dominant element and stays inside its card on a phone', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpHostedSession(tester, sessionId: 'L6RNU');

    final code = tester.getRect(find.text('L6RNU'));
    final label = tester.getRect(find.text(t.watchTogether.sessionCode));
    final card = tester.getRect(find.ancestor(of: find.text('L6RNU'), matching: find.byType(Card)).first);

    expect(code.height, greaterThanOrEqualTo(label.height * 2), reason: 'the code must read from across a room');
    expect(card.contains(code.topLeft) && card.contains(code.bottomRight), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a maximum-length custom code scales down instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final longCode = 'A' * 64;
    await pumpHostedSession(tester, sessionId: longCode);

    final code = tester.getRect(find.text(longCode));
    final card = tester.getRect(find.ancestor(of: find.text(longCode), matching: find.byType(Card)).first);

    expect(card.contains(code.topLeft) && card.contains(code.bottomRight), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping the code copies it and announces the copy affordance', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    final semantics = tester.ensureSemantics();

    await pumpHostedSession(tester, sessionId: 'L6RNU');

    final copyable = find.bySemanticsLabel(t.watchTogether.copySessionCode);
    expect(copyable, findsOneWidget);
    expect(tester.getSemantics(copyable).getSemanticsData().value, 'L6RNU');

    await tester.tap(find.text('L6RNU'));
    await tester.pump();

    expect(copied, 'L6RNU');
    expect(find.text(t.watchTogether.sessionCodeCopied), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    semantics.dispose();
  });
}

class _FakeWatchTogetherProvider extends WatchTogetherProvider {
  _FakeWatchTogetherProvider({required String sessionId})
    : _session = WatchSession(
        sessionId: sessionId,
        role: SessionRole.host,
        controlMode: ControlMode.anyone,
        state: SessionState.connected,
      );

  final WatchSession _session;

  @override
  WatchSession? get session => _session;

  @override
  bool get isInSession => true;

  @override
  bool get isHost => true;

  @override
  bool get hasCurrentPlayback => false;

  @override
  List<Participant> get participants => const [Participant(peerId: 'local', displayName: 'Local viewer', isHost: true)];

  @override
  int get participantCount => participants.length;

  @override
  bool canTransferHostTo(Participant participant) => false;
}
