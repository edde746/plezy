import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/navigation/profile_navigation_scope.dart';

void main() {
  testWidgets('ProfileNavigationRegistry pops and detaches the active profile navigator', (tester) async {
    final registry = ProfileNavigationRegistry();
    final firstKey = GlobalKey<NavigatorState>();
    final secondKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Navigator(
          key: firstKey,
          onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => const Text('first')),
        ),
      ),
    );

    registry.attachNavigator(firstKey);
    final pushedRoute = firstKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Text('second')));
    await tester.pumpAndSettle();
    expect(find.text('second'), findsOneWidget);

    expect(await registry.maybePopProfileRoute(), isTrue);
    await pushedRoute;
    await tester.pumpAndSettle();
    expect(find.text('second'), findsNothing);

    registry.detachNavigator(secondKey);
    expect(registry.navigator, same(firstKey.currentState));

    registry.detachNavigator(firstKey);
    expect(registry.navigator, isNull);
  });
}
