import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    expect(shouldPass(isShowingProfileSelection: true), isFalse);
    expect(shouldPass(hasVisibleTabs: false), isFalse);
  });

  test('desktop physical Escape is reserved for window fullscreen only at root Home', () {
    bool shouldHandle({
      bool isDesktop = true,
      bool isPhysicalKeyboardEvent = true,
      LogicalKeyboardKey logicalKey = LogicalKeyboardKey.escape,
      bool isCurrentRoute = true,
      bool isHomeTab = true,
    }) {
      return shouldHandleDesktopRootEscape(
        isDesktop: isDesktop,
        isPhysicalKeyboardEvent: isPhysicalKeyboardEvent,
        logicalKey: logicalKey,
        isCurrentRoute: isCurrentRoute,
        isHomeTab: isHomeTab,
      );
    }

    expect(shouldHandle(), isTrue);
    expect(shouldHandle(isHomeTab: false), isFalse);
    expect(shouldHandle(isCurrentRoute: false), isFalse);
    // A remote/gamepad-synthesized escape is not a physical keyboard Escape;
    // it keeps the press-back-again exit path.
    expect(shouldHandle(isPhysicalKeyboardEvent: false), isFalse);
    expect(shouldHandle(isDesktop: false), isFalse);
    expect(shouldHandle(logicalKey: LogicalKeyboardKey.gameButtonB), isFalse);
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

  test('resume prompt is suppressed during active video playback (#2034)', () {
    bool should({
      bool resumedFromBackground = true,
      bool isOffline = false,
      bool alreadyShowingProfileSelection = false,
      bool isMobilePlatform = true,
      bool hasActiveVideoPlayback = false,
    }) {
      return shouldShowProfileSelectionOnResume(
        resumedFromBackground: resumedFromBackground,
        isOffline: isOffline,
        alreadyShowingProfileSelection: alreadyShowingProfileSelection,
        isMobilePlatform: isMobilePlatform,
        hasActiveVideoPlayback: hasActiveVideoPlayback,
      );
    }

    expect(should(), isTrue);
    // Waking the device mid-stream resumes the stream; the picker would
    // fight the player's focus self-heal for the remote.
    expect(should(hasActiveVideoPlayback: true), isFalse);
    expect(should(resumedFromBackground: false), isFalse);
    expect(should(isOffline: true), isFalse);
    expect(should(alreadyShowingProfileSelection: true), isFalse);
    // Desktop "resumed" fires on every window focus gain; startup prompt only.
    expect(should(isMobilePlatform: false), isFalse);
  });

  group('ProfileSelectionResumeGate', () {
    test('does not prompt for overlay-style focus loss and regain (#1990)', () {
      final gate = ProfileSelectionResumeGate();
      expect(gate.consumePromptOn(AppLifecycleState.inactive), isFalse);
      expect(gate.consumePromptOn(AppLifecycleState.resumed), isFalse);
    });

    test('prompts exactly once after a genuine backgrounding', () {
      final gate = ProfileSelectionResumeGate();
      expect(gate.consumePromptOn(AppLifecycleState.inactive), isFalse);
      expect(gate.consumePromptOn(AppLifecycleState.paused), isFalse);
      expect(gate.wasBackgrounded, isTrue);
      expect(gate.consumePromptOn(AppLifecycleState.resumed), isTrue);
      expect(gate.consumePromptOn(AppLifecycleState.resumed), isFalse);
      expect(gate.wasBackgrounded, isFalse);
    });

    test('prompts after an iOS-style hidden -> inactive -> resumed return', () {
      final gate = ProfileSelectionResumeGate();
      expect(gate.consumePromptOn(AppLifecycleState.hidden), isFalse);
      expect(gate.consumePromptOn(AppLifecycleState.inactive), isFalse);
      expect(gate.consumePromptOn(AppLifecycleState.resumed), isTrue);
    });

    test('latches every backgrounding state', () {
      for (final state in [AppLifecycleState.hidden, AppLifecycleState.paused, AppLifecycleState.detached]) {
        final gate = ProfileSelectionResumeGate();
        expect(gate.consumePromptOn(state), isFalse);
        expect(gate.consumePromptOn(AppLifecycleState.resumed), isTrue, reason: '$state');
      }
    });

    test('does not prompt without a prior backgrounding (cold open)', () {
      final gate = ProfileSelectionResumeGate();
      expect(gate.consumePromptOn(AppLifecycleState.resumed), isFalse);
    });
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
