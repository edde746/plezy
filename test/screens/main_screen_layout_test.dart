import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/profiles/plex_home_service.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_connection_registry.dart';
import 'package:plezy/profiles/profile_registry.dart';
import 'package:plezy/screens/main_screen.dart';
import 'package:plezy/services/storage_service.dart';
import 'package:plezy/widgets/side_navigation_rail.dart';

import '../test_helpers/prefs.dart';

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

  test('resume prompt shows over playback but not during companion sessions (#2087)', () {
    bool should({
      bool resumedFromBackground = true,
      bool isOffline = false,
      bool alreadyShowingProfileSelection = false,
      bool isMobilePlatform = true,
      bool hasActiveCompanionRemoteSession = false,
    }) {
      return shouldShowProfileSelectionOnResume(
        resumedFromBackground: resumedFromBackground,
        isOffline: isOffline,
        alreadyShowingProfileSelection: alreadyShowingProfileSelection,
        isMobilePlatform: isMobilePlatform,
        hasActiveCompanionRemoteSession: hasActiveCompanionRemoteSession,
      );
    }

    // A paused show must not let another person resume the session, so the
    // picker still shows over an active player when "ask on open" is set.
    expect(should(), isTrue);
    // A phone driving another device backgrounds constantly; the picker +
    // PIN would bury the live remote session.
    expect(should(hasActiveCompanionRemoteSession: true), isFalse);
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

    test('does not prompt when the session keeps playing in PiP (#2195)', () {
      final gate = ProfileSelectionResumeGate();
      expect(gate.consumePromptOn(AppLifecycleState.hidden, pipContinuation: true), isFalse);
      expect(gate.consumePromptOn(AppLifecycleState.paused, pipContinuation: true), isFalse);
      expect(gate.wasBackgrounded, isFalse);
      expect(gate.consumePromptOn(AppLifecycleState.resumed), isFalse);
    });

    test('a non-PiP frame still arms even if a later frame reports PiP', () {
      final gate = ProfileSelectionResumeGate();
      expect(gate.consumePromptOn(AppLifecycleState.paused), isFalse);
      expect(gate.wasBackgrounded, isTrue);
      // A later PiP-reporting frame must not clear an already-armed latch.
      expect(gate.consumePromptOn(AppLifecycleState.hidden, pipContinuation: true), isFalse);
      expect(gate.consumePromptOn(AppLifecycleState.resumed), isTrue);
    });
  });

  group('ContentRefreshResumeGate', () {
    // Injectable clock: tests advance `now` instead of sleeping.
    ContentRefreshResumeGate gateAt(DateTime Function() now) =>
        ContentRefreshResumeGate(staleAfter: const Duration(minutes: 5), now: now);

    test('refreshes once after a backgrounding longer than the threshold (#2043)', () {
      var now = DateTime(2026, 8, 20, 12);
      final gate = gateAt(() => now);
      expect(gate.consumeRefreshOn(AppLifecycleState.paused), isFalse);
      now = now.add(const Duration(hours: 18));
      expect(gate.consumeRefreshOn(AppLifecycleState.resumed), isTrue);
      // Consumed: an immediate second resume must not refresh again.
      expect(gate.consumeRefreshOn(AppLifecycleState.resumed), isFalse);
    });

    test('does not refresh after a short backgrounding', () {
      var now = DateTime(2026, 8, 20, 12);
      final gate = gateAt(() => now);
      expect(gate.consumeRefreshOn(AppLifecycleState.hidden), isFalse);
      now = now.add(const Duration(minutes: 4, seconds: 59));
      expect(gate.consumeRefreshOn(AppLifecycleState.resumed), isFalse);
    });

    test('does not refresh for overlay-style inactive -> resumed', () {
      var now = DateTime(2026, 8, 20, 12);
      final gate = gateAt(() => now);
      expect(gate.consumeRefreshOn(AppLifecycleState.inactive), isFalse);
      now = now.add(const Duration(hours: 1));
      expect(gate.consumeRefreshOn(AppLifecycleState.resumed), isFalse);
    });

    test('does not refresh on a cold-open resume with no prior backgrounding', () {
      final gate = gateAt(DateTime.now);
      expect(gate.consumeRefreshOn(AppLifecycleState.resumed), isFalse);
    });

    test('keeps the earliest backgrounded time across hidden -> paused churn', () {
      var now = DateTime(2026, 8, 20, 12);
      final gate = gateAt(() => now);
      expect(gate.consumeRefreshOn(AppLifecycleState.hidden), isFalse);
      now = now.add(const Duration(minutes: 4));
      // A later deeper state must not restart the clock.
      expect(gate.consumeRefreshOn(AppLifecycleState.paused), isFalse);
      now = now.add(const Duration(minutes: 2));
      expect(gate.consumeRefreshOn(AppLifecycleState.resumed), isTrue);
    });

    test('resume resets the latch for the next backgrounding', () {
      var now = DateTime(2026, 8, 20, 12);
      final gate = gateAt(() => now);
      expect(gate.consumeRefreshOn(AppLifecycleState.paused), isFalse);
      now = now.add(const Duration(minutes: 1));
      expect(gate.consumeRefreshOn(AppLifecycleState.resumed), isFalse);
      // The stale clock must start from the *new* backgrounding, not the old one.
      expect(gate.consumeRefreshOn(AppLifecycleState.paused), isFalse);
      now = now.add(const Duration(minutes: 5));
      expect(gate.consumeRefreshOn(AppLifecycleState.resumed), isTrue);
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

  group('runInitialProfilePrompt', () {
    Future<_PromptFixture> makeFixture() async {
      resetSharedPreferencesForTest();
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final connections = ConnectionRegistry(db);
      final profileConnections = ProfileConnectionRegistry(db);
      final profiles = ProfileRegistry(db);
      final storage = await StorageService.getInstance();
      final plexHome = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: (_) async => const [],
      );
      final active = _GatedInitializeActiveProfileProvider(
        registry: profiles,
        plexHome: plexHome,
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
      );
      addTearDown(() async {
        await active.resetForTesting();
        active.dispose();
        await plexHome.dispose();
        await db.close();
      });
      return _PromptFixture(profiles: profiles, storage: storage, active: active);
    }

    test('mid-initialize synchronous notify pushes exactly one requireSelection picker', () async {
      final fixture = await makeFixture();
      // Two selectable profiles, none active: the prompt must push the picker.
      await fixture.profiles.upsert(Profile.local(id: 'p1', displayName: 'One', createdAt: DateTime(2026, 1, 1)));
      await fixture.profiles.upsert(Profile.local(id: 'p2', displayName: 'Two', createdAt: DateTime(2026, 1, 2)));

      var claimed = false;
      var pushes = 0;
      final pickerPopped = Completer<void>();
      final runs = <Future<void>>[];

      Future<void> run() => runInitialProfilePrompt(
        activeProfile: fixture.active,
        claimPrompt: () {
          if (claimed) return false;
          claimed = true;
          return true;
        },
        releasePrompt: () => claimed = false,
        isMounted: () => true,
        isOfflineMode: false,
        hasConnections: () async => fail('zero-profiles settle branch must not run'),
        settleSession: () async => fail('zero-profiles settle branch must not run'),
        pushProfileSelection: () async {
          pushes++;
          // The real picker route stays up until the user selects a profile.
          await pickerPopped.future;
        },
      );

      // The late-profiles re-arm: any provider notification landing while the
      // first prompt is parked on initialize() re-enters the prompt, exactly
      // like _onActiveProfileChanged does.
      fixture.active.addListener(() => runs.add(run()));

      // Parks on the gated initialize after its synchronous notify re-entered.
      runs.add(run());
      expect(runs, hasLength(2), reason: 'the gated initialize notified synchronously');

      fixture.active.initializeGate.complete();
      await pumpEventQueue();
      expect(pushes, 1);

      // A notification landing while the picker route is up (e.g. the
      // connection watcher) must not stack a second requireSelection picker.
      fixture.active.emitExternalNotify();
      await pumpEventQueue();
      expect(pushes, 1);

      pickerPopped.complete();
      await Future.wait(runs);
      expect(pushes, 1);
      expect(claimed, isFalse, reason: 'claim released after the picker resolves');
    });

    test('non-push exit releases the double-push claim', () async {
      final fixture = await makeFixture();
      // One profile, already active, "require selection on open" off: the
      // prompt must decline to push and release its claim so a later genuine
      // prompt is still possible.
      await fixture.profiles.upsert(Profile.local(id: 'p1', displayName: 'One', createdAt: DateTime(2026, 1, 1)));
      await fixture.storage.setActiveProfileId('p1');
      fixture.active.initializeGate.complete();

      var claimed = false;
      var pushes = 0;

      Future<void> run() => runInitialProfilePrompt(
        activeProfile: fixture.active,
        claimPrompt: () {
          if (claimed) return false;
          claimed = true;
          return true;
        },
        releasePrompt: () => claimed = false,
        isMounted: () => true,
        isOfflineMode: false,
        hasConnections: () async => fail('zero-profiles settle branch must not run'),
        settleSession: () async => fail('zero-profiles settle branch must not run'),
        pushProfileSelection: () async => pushes++,
      );

      await run();
      expect(pushes, 0);
      expect(claimed, isFalse, reason: 'a non-push exit must release the claim');

      // The released claim keeps future prompts reachable.
      await run();
      expect(pushes, 0);
      expect(claimed, isFalse);
    });
  });
}

class _PromptFixture {
  _PromptFixture({required this.profiles, required this.storage, required this.active});

  final ProfileRegistry profiles;
  final StorageService storage;
  final _GatedInitializeActiveProfileProvider active;
}

/// [ActiveProfileProvider] whose [initialize] parks on [initializeGate] after
/// notifying — the fresh sign-in shape where the provider's connection watcher
/// notifies while MainScreen's prompt is still awaiting initialize().
class _GatedInitializeActiveProfileProvider extends ActiveProfileProvider {
  _GatedInitializeActiveProfileProvider({
    required super.registry,
    required super.plexHome,
    required super.connections,
    required super.profileConnections,
    required super.storage,
  });

  final Completer<void> initializeGate = Completer<void>();

  @override
  Future<void> initialize() async {
    notifyListeners();
    await initializeGate.future;
    await super.initialize();
  }

  /// A notification from outside the prompt (e.g. a connection table write).
  void emitExternalNotify() => notifyListeners();
}
