import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/back_press.dart';
import 'package:plezy/focus/navigator_back_handler.dart';
import 'package:plezy/utils/platform_detector.dart';

/// Root navigator wrapped the way `main.dart` wraps it. [home] is the root
/// route; a [nested] navigator (wrapped the way the profile session wraps it)
/// can be mounted inside it.
class _Harness extends StatelessWidget {
  const _Harness({required this.rootKey, required this.home});

  final GlobalKey<NavigatorState> rootKey;
  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootKey,
      home: home,
      builder: (_, child) => NavigatorBackHandler(navigatorKey: rootKey, child: child!),
    );
  }
}

class _Nested extends StatelessWidget {
  const _Nested({required this.nestedKey, required this.home});

  final GlobalKey<NavigatorState> nestedKey;
  final Widget home;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        nestedKey.currentState?.maybePop();
      },
      child: NavigatorBackHandler(
        navigatorKey: nestedKey,
        child: Navigator(
          key: nestedKey,
          onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => home),
        ),
      ),
    );
  }
}

/// A screen whose back policy lives in its PopScope, like every migrated screen.
class _Screen extends StatelessWidget {
  const _Screen({required this.label, this.canPop = true, this.onBack});

  final String label;
  final bool canPop;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        onBack?.call();
      },
      child: Focus(autofocus: true, debugLabel: label, child: Text(label)),
    );
  }
}

Future<void> _press(WidgetTester tester, [LogicalKeyboardKey key = LogicalKeyboardKey.escape]) async {
  await tester.sendKeyDownEvent(key);
  await tester.sendKeyUpEvent(key);
  await tester.pump();
  await tester.pump();
}

void main() {
  setUp(() => TvDetectionService.debugSetAppleTVOverride(false));
  tearDown(() => TvDetectionService.debugSetAppleTVOverride(null));

  testWidgets('a Back key on a pushed route pops it, once', (tester) async {
    final rootKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      _Harness(
        rootKey: rootKey,
        home: const _Screen(label: 'home'),
      ),
    );
    rootKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => const _Screen(label: 'detail')));
    await tester.pumpAndSettle();
    expect(find.text('detail'), findsOneWidget);

    await _press(tester);
    await tester.pumpAndSettle();

    expect(find.text('detail'), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('a Back key reaches the route PopScope when canPop is false', (tester) async {
    final rootKey = GlobalKey<NavigatorState>();
    var backs = 0;
    await tester.pumpWidget(
      _Harness(
        rootKey: rootKey,
        home: _Screen(label: 'home', canPop: false, onBack: () => backs++),
      ),
    );
    await tester.pump();

    await _press(tester);
    expect(backs, 1);

    // Repeat events of a held press never re-fire.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump();
    expect(backs, 2);
  });

  testWidgets('a Back press racing a push is swallowed instead of popping the new route', (tester) async {
    final rootKey = GlobalKey<NavigatorState>();
    var homeBacks = 0;
    await tester.pumpWidget(
      _Harness(
        rootKey: rootKey,
        home: _Screen(label: 'home', canPop: false, onBack: () => homeBacks++),
      ),
    );
    await tester.pump();

    // Focus is still on the covered route until the new route's autofocus
    // lands in a later microtask/frame.
    rootKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => const _Screen(label: 'detail')));
    expect(await simulateKeyDownEvent(LogicalKeyboardKey.escape), isTrue);
    expect(await simulateKeyUpEvent(LogicalKeyboardKey.escape), isTrue);
    await tester.pumpAndSettle();

    expect(find.text('detail'), findsOneWidget);
    expect(homeBacks, 0);
  });

  testWidgets('a Back key at the true root with nothing to pop is left to the platform', (tester) async {
    final rootKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      _Harness(
        rootKey: rootKey,
        home: const _Screen(label: 'home'),
      ),
    );
    await tester.pump();

    // Unhandled: the framework reports false, so the Android embedding may
    // redispatch it into onBackPressed and exit the app.
    expect(await simulateKeyDownEvent(LogicalKeyboardKey.escape), isFalse);
    expect(await simulateKeyUpEvent(LogicalKeyboardKey.escape), isFalse);
  });

  testWidgets('a focused owner consumes Back before the route', (tester) async {
    final rootKey = GlobalKey<NavigatorState>();
    var owned = 0;
    var popped = 0;
    await tester.pumpWidget(
      _Harness(
        rootKey: rootKey,
        home: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) => popped++,
          child: BackKeyOwner(
            onBack: () => owned++,
            child: const Focus(autofocus: true, child: SizedBox.expand()),
          ),
        ),
      ),
    );
    await tester.pump();

    await _press(tester);
    expect(owned, 1);
    expect(popped, 0);
  });

  testWidgets('the KeyUp of a KeyDown-fired pop lands on the uncovered route and does nothing', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final rootKey = GlobalKey<NavigatorState>();
    var homeBacks = 0;
    await tester.pumpWidget(
      _Harness(
        rootKey: rootKey,
        home: _Screen(label: 'home', canPop: false, onBack: () => homeBacks++),
      ),
    );
    rootKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => const _Screen(label: 'detail')));
    await tester.pumpAndSettle();

    // Apple TV acts on KeyDown: the detail route is gone before the KeyUp.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('detail'), findsNothing);

    expect(await simulateKeyUpEvent(LogicalKeyboardKey.escape), isTrue, reason: 'orphan KeyUp is swallowed');
    await tester.pumpAndSettle();
    expect(homeBacks, 0);

    // The next full press is a fresh one and does act.
    await _press(tester);
    expect(homeBacks, 1);
  });

  testWidgets('an owner that acted on KeyDown and moved focus leaves nothing for the route', (tester) async {
    final rootKey = GlobalKey<NavigatorState>();
    final target = FocusNode(debugLabel: 'target');
    addTearDown(target.dispose);
    var popped = 0;
    await tester.pumpWidget(
      _Harness(
        rootKey: rootKey,
        home: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) => popped++,
          child: Column(
            children: [
              BackKeyOwner(
                phase: BackPhase.keyDown,
                onBack: target.requestFocus,
                child: const Focus(autofocus: true, child: SizedBox(height: 10)),
              ),
              Focus(focusNode: target, child: const SizedBox(height: 10)),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(target.hasPrimaryFocus, isTrue);
    expect(await simulateKeyUpEvent(LogicalKeyboardKey.escape), isTrue, reason: 'orphan KeyUp is swallowed');
    await tester.pump();
    await tester.pump();
    expect(popped, 0);
  });

  testWidgets('a root dialog over a nested navigator is popped by the root handler only', (tester) async {
    final rootKey = GlobalKey<NavigatorState>();
    final nestedKey = GlobalKey<NavigatorState>();
    var nestedBacks = 0;
    await tester.pumpWidget(
      _Harness(
        rootKey: rootKey,
        home: _Nested(
          nestedKey: nestedKey,
          home: _Screen(label: 'main', canPop: false, onBack: () => nestedBacks++),
        ),
      ),
    );
    await tester.pumpAndSettle();

    unawaited(
      showDialog<void>(
        context: rootKey.currentContext!,
        builder: (_) => const AlertDialog(content: Focus(autofocus: true, child: Text('dialog'))),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('dialog'), findsOneWidget);

    await _press(tester);
    await tester.pumpAndSettle();

    expect(find.text('dialog'), findsNothing);
    expect(nestedBacks, 0);
  });

  testWidgets('Back inside the nested navigator reaches the nested route policy', (tester) async {
    final rootKey = GlobalKey<NavigatorState>();
    final nestedKey = GlobalKey<NavigatorState>();
    var nestedBacks = 0;
    await tester.pumpWidget(
      _Harness(
        rootKey: rootKey,
        home: _Nested(
          nestedKey: nestedKey,
          home: _Screen(label: 'main', canPop: false, onBack: () => nestedBacks++),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _press(tester);
    expect(nestedBacks, 1);

    // A pushed nested route pops on Back; the root navigator is untouched.
    nestedKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => const _Screen(label: 'nested detail')));
    await tester.pumpAndSettle();
    await _press(tester);
    await tester.pumpAndSettle();
    expect(find.text('nested detail'), findsNothing);
    expect(find.text('main'), findsOneWidget);
    expect(nestedBacks, 1);
  });

  testWidgets('gameButtonB and goBack are Back keys too', (tester) async {
    final rootKey = GlobalKey<NavigatorState>();
    var backs = 0;
    await tester.pumpWidget(
      _Harness(
        rootKey: rootKey,
        home: _Screen(label: 'home', canPop: false, onBack: () => backs++),
      ),
    );
    await tester.pump();

    await _press(tester, LogicalKeyboardKey.gameButtonB);
    expect(backs, 1);
  });
}
