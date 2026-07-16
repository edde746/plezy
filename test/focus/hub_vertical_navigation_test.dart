import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/hub_vertical_navigation.dart';

void main() {
  test('empty hub lists do not consume navigation', () {
    expect(
      navigateVerticalHubRows(
        hubCount: 0,
        hubIndex: 0,
        isUp: true,
        requestFocus: (_) => fail('must not request focus'),
      ),
      isFalse,
    );
  });

  test('valid movement requests the adjacent row and consumes', () {
    int? requested;

    final handled = navigateVerticalHubRows(
      hubCount: 3,
      hubIndex: 1,
      isUp: false,
      requestFocus: (index) => requested = index,
    );

    expect(handled, isTrue);
    expect(requested, 2);
  });

  test('top boundary can propagate to the row callback', () {
    expect(
      navigateVerticalHubRows(
        hubCount: 2,
        hubIndex: 0,
        isUp: true,
        propagateTopBoundary: true,
        requestFocus: (_) => fail('must not request focus'),
      ),
      isFalse,
    );
  });

  test('explicit top handoff consumes navigation', () {
    var handoffs = 0;

    final handled = navigateVerticalHubRows(
      hubCount: 2,
      hubIndex: 0,
      isUp: true,
      onTopBoundary: () => handoffs++,
      requestFocus: (_) => fail('must not request focus'),
    );

    expect(handled, isTrue);
    expect(handoffs, 1);
  });

  test('bottom boundary invokes its handoff and always consumes', () {
    var handoffs = 0;

    final handled = navigateVerticalHubRows(
      hubCount: 2,
      hubIndex: 1,
      isUp: false,
      onBottomBoundary: () => handoffs++,
      requestFocus: (_) => fail('must not request focus'),
    );

    expect(handled, isTrue);
    expect(handoffs, 1);
  });
}
