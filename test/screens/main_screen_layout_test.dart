import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/screens/main_screen.dart';
import 'package:plezy/widgets/side_navigation_rail.dart';

void main() {
  test('side navigation pushes stable foreground off-screen while temporarily expanded', () {
    const viewportWidth = 1280.0;
    const reservedWidth = SideNavigationRailState.tvCollapsedWidth;

    final collapsed = mainScreenSideNavigationContentLayout(
      viewportWidth: viewportWidth,
      currentSideNavigationWidth: SideNavigationRailState.tvCollapsedWidth,
      reservedSideNavigationWidth: reservedWidth,
    );
    final expanded = mainScreenSideNavigationContentLayout(
      viewportWidth: viewportWidth,
      currentSideNavigationWidth: SideNavigationRailState.expandedWidth,
      reservedSideNavigationWidth: reservedWidth,
    );

    expect(collapsed.width, viewportWidth - SideNavigationRailState.tvCollapsedWidth);
    expect(expanded.width, collapsed.width);
    expect(collapsed.left, SideNavigationRailState.tvCollapsedWidth);
    expect(expanded.left, SideNavigationRailState.expandedWidth);
    expect(collapsed.left + collapsed.width, viewportWidth);
    expect(expanded.left + expanded.width, viewportWidth + SideNavigationRailState.expandedWidth - reservedWidth);
  });

  test('side navigation reserves expanded width when always open', () {
    const viewportWidth = 1280.0;

    final expanded = mainScreenSideNavigationContentLayout(
      viewportWidth: viewportWidth,
      currentSideNavigationWidth: SideNavigationRailState.expandedWidth,
      reservedSideNavigationWidth: SideNavigationRailState.expandedWidth,
    );

    expect(expanded.left, SideNavigationRailState.expandedWidth);
    expect(expanded.width, viewportWidth - SideNavigationRailState.expandedWidth);
    expect(expanded.left + expanded.width, viewportWidth);
  });
}
