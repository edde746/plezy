import 'package:flutter/material.dart';
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

  test('tvOS Menu pass-through only enables at root with sidebar focus', () {
    bool shouldPass({
      bool isAppleTV = true,
      bool isShowingProfileSelection = false,
      bool isOverlaySheetOpen = false,
      bool isRouteCurrent = true,
      bool isSidebarFocused = true,
      bool hasVisibleTabs = true,
      bool isCurrentTabRoot = true,
    }) {
      return shouldPassTvosMenuToSystem(
        isAppleTV: isAppleTV,
        isShowingProfileSelection: isShowingProfileSelection,
        isOverlaySheetOpen: isOverlaySheetOpen,
        isRouteCurrent: isRouteCurrent,
        isSidebarFocused: isSidebarFocused,
        hasVisibleTabs: hasVisibleTabs,
        isCurrentTabRoot: isCurrentTabRoot,
      );
    }

    expect(shouldPass(), isTrue);
    expect(shouldPass(isSidebarFocused: false), isFalse);
    expect(shouldPass(isCurrentTabRoot: false), isFalse);
    expect(shouldPass(isOverlaySheetOpen: true), isFalse);
    expect(shouldPass(isRouteCurrent: false), isFalse);
    expect(shouldPass(isAppleTV: false), isFalse);
  });

  test('profile switch invalidates nothing here — the keyed session remount owns it', () {
    expect(
      profileInvalidationAction(
        previousProfileId: 'owner',
        currentProfileId: 'kids',
        wasBindingPreviously: false,
        isBindingNow: false,
      ),
      ProfileInvalidationAction.none,
    );
  });

  test('same-profile rebind invalidates once when binding settles', () {
    expect(
      profileInvalidationAction(
        previousProfileId: 'owner',
        currentProfileId: 'owner',
        wasBindingPreviously: true,
        isBindingNow: false,
      ),
      ProfileInvalidationAction.invalidateNow,
    );

    expect(
      profileInvalidationAction(
        previousProfileId: 'owner',
        currentProfileId: 'owner',
        wasBindingPreviously: false,
        isBindingNow: false,
      ),
      ProfileInvalidationAction.none,
    );
  });

  testWidgets('side navigation bleed animates from the previous value', (tester) async {
    Widget build(double targetBleed) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            SideNavigationBleedBuilder(
              targetBleed: targetBleed,
              builder: (context, bleed, _) => Positioned(
                key: const ValueKey('bleed-position'),
                top: 0,
                left: -bleed,
                width: 1280,
                height: 10,
                child: const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      );
    }

    double left() => tester.widget<Positioned>(find.byKey(const ValueKey('bleed-position'))).left!;

    await tester.pumpWidget(build(SideNavigationRailState.tvCollapsedWidth));
    expect(left(), -SideNavigationRailState.tvCollapsedWidth);

    await tester.pumpWidget(build(SideNavigationRailState.expandedWidth));
    expect(left(), closeTo(-SideNavigationRailState.tvCollapsedWidth, 0.001));

    await tester.pump(const Duration(milliseconds: 100));
    expect(left(), lessThan(-SideNavigationRailState.tvCollapsedWidth));
    expect(left(), greaterThan(-SideNavigationRailState.expandedWidth));

    await tester.pumpAndSettle();
    expect(left(), closeTo(-SideNavigationRailState.expandedWidth, 0.001));
  });
}
