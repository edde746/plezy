import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/main.dart';

void main() {
  testWidgets('renders a Flutter frame before starting the initialization gate', (tester) async {
    final completion = Completer<int>();
    var bootstrapWasMounted = false;

    await tester.pumpWidget(
      StartupBootstrap<int>(
        initialize: () {
          bootstrapWasMounted = find.byKey(startupBootstrapProgressKey).evaluate().isNotEmpty;
          return completion.future;
        },
        buildApp: (_, value) => MaterialApp(home: Text('ready $value')),
      ),
    );

    expect(bootstrapWasMounted, isTrue);
    expect(find.byKey(startupBootstrapProgressKey), findsOneWidget);

    completion.complete(1);
    await tester.pump();
  });

  testWidgets('replaces bootstrap UI with the initialized app on success', (tester) async {
    final completion = Completer<int>();

    await tester.pumpWidget(
      StartupBootstrap<int>(
        initialize: () => completion.future,
        buildApp: (_, value) => MaterialApp(home: Text('ready $value')),
      ),
    );

    completion.complete(7);
    await tester.pump();

    expect(find.text('ready 7'), findsOneWidget);
    expect(find.byKey(startupBootstrapProgressKey), findsNothing);
  });

  testWidgets('shows a localized recoverable failure instead of removing Flutter UI', (tester) async {
    await tester.pumpWidget(
      StartupBootstrap<int>(
        initialize: () async => throw StateError('database unavailable'),
        buildApp: (_, value) => Text('ready $value'),
      ),
    );
    await tester.pump();

    expect(find.byKey(startupBootstrapFailureKey), findsOneWidget);
    expect(find.text('Error'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('retry clears the failed generation and can commit a later success', (tester) async {
    final retryCompletion = Completer<int>();
    var attempts = 0;

    await tester.pumpWidget(
      StartupBootstrap<int>(
        initialize: () {
          attempts++;
          if (attempts == 1) return Future<int>.error(StateError('first attempt'));
          return retryCompletion.future;
        },
        buildApp: (_, value) => MaterialApp(home: Text('ready $value')),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(startupBootstrapRetryKey));
    await tester.pump();
    expect(attempts, 2);
    expect(find.byKey(startupBootstrapProgressKey), findsOneWidget);

    retryCompletion.complete(42);
    await tester.pump();

    expect(find.text('ready 42'), findsOneWidget);
    expect(find.byKey(startupBootstrapFailureKey), findsNothing);
  });

  testWidgets('discards a completion from a disposed bootstrap generation', (tester) async {
    final completion = Completer<int>();
    final discarded = <int>[];

    await tester.pumpWidget(
      StartupBootstrap<int>(
        initialize: () => completion.future,
        buildApp: (_, value) => Text('ready $value'),
        discard: discarded.add,
      ),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    completion.complete(9);
    await tester.pump();

    expect(discarded, [9]);
    expect(find.text('ready 9'), findsNothing);
  });
}
