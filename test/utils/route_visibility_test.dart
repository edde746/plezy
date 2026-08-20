import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/route_visibility.dart';

void main() {
  testWidgets('isRouteChainCurrent sees routes pushed on the own and ancestor navigators (#2034)', (tester) async {
    final nestedNavigatorKey = GlobalKey<NavigatorState>();
    const contentKey = Key('nested-content');
    const nestedAboveKey = Key('nested-above');
    const rootAboveKey = Key('root-above');

    await tester.pumpWidget(
      MaterialApp(
        home: Navigator(
          key: nestedNavigatorKey,
          onGenerateRoute: (settings) => MaterialPageRoute<void>(builder: (_) => const SizedBox(key: contentKey)),
        ),
      ),
    );

    // The covered content stays mounted (maintainState) but goes offstage.
    BuildContext content() => tester.element(find.byKey(contentKey, skipOffstage: false));

    expect(isRouteChainCurrent(content()), isTrue, reason: 'sole route is current');

    // A route above on the SAME (nested) navigator.
    unawaited(
      nestedNavigatorKey.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const SizedBox(key: nestedAboveKey)),
      ),
    );
    await tester.pumpAndSettle();
    expect(isRouteChainCurrent(content()), isFalse, reason: 'covered on own navigator');
    expect(isRouteChainCurrent(tester.element(find.byKey(nestedAboveKey))), isTrue);

    nestedNavigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(isRouteChainCurrent(content()), isTrue, reason: 'uncovered after nested pop');

    // A route above on the ROOT navigator — the profile-picker-over-player
    // shape from #2034: the nested route's own isCurrent stays true.
    unawaited(
      Navigator.of(
        content(),
        rootNavigator: true,
      ).push(MaterialPageRoute<void>(builder: (_) => const SizedBox(key: rootAboveKey))),
    );
    await tester.pumpAndSettle();
    expect(isRouteChainCurrent(content()), isFalse, reason: 'covered on ancestor navigator');
    expect(isRouteChainCurrent(tester.element(find.byKey(rootAboveKey))), isTrue);

    Navigator.of(content(), rootNavigator: true).pop();
    await tester.pumpAndSettle();
    expect(isRouteChainCurrent(content()), isTrue, reason: 'uncovered after root pop');
  });
}
