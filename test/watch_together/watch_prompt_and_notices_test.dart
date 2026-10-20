import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openwatchparty/openwatchparty.dart' as owp;
import 'package:plezy/focus/key_event_utils.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/navigation/profile_navigation_scope.dart';
import 'package:plezy/screens/video_player/widgets/player_prompt_overlays.dart';
import 'package:plezy/services/pip_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/watch_together/models/watch_notice.dart';
import 'package:plezy/watch_together/providers/watch_together_provider.dart';
import 'package:plezy/watch_together/widgets/watch_labels.dart';
import 'package:plezy/watch_together/widgets/watch_notice_listener.dart';
import 'package:plezy/watch_together/widgets/watch_room_sections.dart';
import 'package:plezy/watch_together/widgets/watch_session_sheet.dart';
import 'package:plezy/watch_together/widgets/watch_together_overlay.dart';

import '../test_helpers/prefs.dart';
import '../test_helpers/watch_room_harness.dart';

void _watchTest(String description, Future<void> Function(WidgetTester tester, WatchRoomHarness world) body) {
  testWidgets(description, (tester) async {
    final world = WatchRoomHarness(tester);
    try {
      await body(tester, world);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await world.close();
    }
  });
}

const _alienMs = 7020000;
const _aliensMs = 8220000;

/// The guest's copies: Alien 5 and 10 minutes longer than the host's, and
/// Aliens 2 minutes shorter.
MediaItem _alien5 = watchMovie(
  id: 'g-alien-5',
  serverId: watchGuestServerId,
  durationMs: _alienMs + 300000,
  version: 'g-5',
);
MediaItem _alien10 = watchMovie(
  id: 'g-alien-10',
  serverId: watchGuestServerId,
  durationMs: _alienMs + 600000,
  version: 'g-10',
);
MediaItem _aliens = watchMovie(
  id: 'g-aliens',
  serverId: watchGuestServerId,
  title: 'Aliens',
  year: 1986,
  durationMs: _aliensMs - 120000,
  version: 'g-a',
);

MediaItem _hostAlien() => watchMovie(id: 'alien');
MediaItem _hostAliens() => watchMovie(id: 'aliens', title: 'Aliens', year: 1986, durationMs: _aliensMs);

/// A guest who has [_alien5], [_alien10] and [_aliens], and whose player
/// opens what the room plays.
(WatchTogetherProvider, WatchTestScreen) _guest(WatchRoomHarness world) {
  final guest = world.guest(copies: () => [_alien5, _alien10, _aliens]);
  return (guest, WatchTestScreen(guest));
}

/// Opens the player page for [provider] with a tap.
Future<void> _openPlayer(WidgetTester tester, WatchTogetherProvider provider) async {
  await tester.pumpWidget(watchTestApp(provider, home: const WatchTestLauncher(screen: WatchTestPlayerPage())));
  await tester.tap(find.text(WatchTestLauncher.label));
  await settleWatchFrames(tester);
}

/// Opens the player page as a keyboard or remote user does, and focuses its
/// room pill.
Future<void> _openPlayerWithKeys(WidgetTester tester, WatchTogetherProvider provider) async {
  await tester.pumpWidget(watchTestApp(provider, home: const WatchTestLauncher(screen: WatchTestPlayerPage())));
  await pressWatchKey(tester, LogicalKeyboardKey.arrowDown);
  await pressWatchKey(tester, LogicalKeyboardKey.enter);
  await pressWatchKey(tester, LogicalKeyboardKey.arrowDown);
  expect(_pillFocused(), isTrue, reason: 'focus is on ${describeWatchFocus()}');
}

bool _pillFocused() {
  final context = FocusManager.instance.primaryFocus?.context;
  return context != null && context.findAncestorWidgetOfExactType<WatchTogetherSessionIndicator>() != null;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await settleWatchFrames(tester);
}

final _prompt = find.byType(WatchMismatchPrompt);

/// Waits until [provider] has a mismatch to answer, and lets the launcher
/// react.
Future<void> _untilMismatch(WidgetTester tester, WatchRoomHarness world, WatchTogetherProvider provider) async {
  await world.until(() => provider.state.mismatch != null, 'the guest has a mismatch');
  await settleWatchFrames(tester);
}

Finder _inOverlays(Finder finder) =>
    find.descendant(of: find.byType(VideoPlayerWatchTogetherOverlays), matching: finder);

Finder _snackBarText(String text) => find.descendant(of: find.byType(SnackBar), matching: find.text(text));

void main() {
  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    LocaleSettings.setLocaleSync(AppLocale.en);
    PlatformDetector.debugSetIsDesktopOSOverride(false);
    TvDetectionService.debugSetAppleTVOverride(false);
    PipService().isPipActive.value = false;
  });

  tearDown(() {
    PlatformDetector.debugSetIsDesktopOSOverride(null);
    TvDetectionService.debugSetAppleTVOverride(null);
    BackKeyCoordinator.clear();
  });

  group('mismatch prompt', () {
    _watchTest('asks once about a copy of another length, with the closest copy and the difference', (
      tester,
      world,
    ) async {
      final host = world.host();
      final (guest, screen) = _guest(world);
      await world.together(host, [guest]);
      await _openPlayer(tester, guest);
      expect(_prompt, findsNothing);

      await world.hostPlays(host, _hostAlien());
      await _untilMismatch(tester, world, guest);
      expect(_prompt, findsOneWidget);
      expect(find.text(t.watchTogether.mismatchTitle), findsOneWidget);
      expect(
        find.text(t.watchTogether.mismatchDescription(difference: watchLengthDifference(300000))),
        findsOneWidget,
        reason: 'the closest copy is offered',
      );
      expect(find.text(t.watchTogether.playAnyway), findsOneWidget);
      expect(find.text(t.watchTogether.chooseAnotherCopy), findsOneWidget);
      expect(find.text(t.watchTogether.dontPlay), findsOneWidget);
      expect(screen.players, isEmpty, reason: 'nothing plays until the user answers');

      // Closed unanswered, it does not come back for the same mismatch.
      await tester.binding.handlePopRoute();
      await settleWatchFrames(tester);
      expect(_prompt, findsNothing);
      expect(find.byType(WatchTestPlayerPage), findsOneWidget);
      host.setLocked(true);
      await world.until(() => guest.isLocked, 'the guest sees the lock');
      host.setControl(owp.Control.everyone);
      await world.until(() => guest.canControl, 'the guest sees the control');
      await settleWatchFrames(tester);
      expect(_prompt, findsNothing);
      expect(guest.state.mismatch, isNotNull, reason: 'the mismatch still waits for an answer');

      // The session sheet still offers the answer.
      await _tap(tester, find.byType(WatchTogetherSessionIndicator));
      expect(find.text(t.watchTogether.mismatchTitle), findsOneWidget, reason: 'the media row says it');
      await _tap(tester, find.text('Alien (1979)'));
      expect(find.byType(WatchMismatchBlock), findsOneWidget);
      await _tap(tester, find.text(t.watchTogether.playAnyway));
      await world.until(() => guest.isFollowing, 'the guest plays the copy');
      expect(guest.state.match?.state, owp.MatchState.mismatched);
      expect(screen.players.single.adapter.copy, watchCopyOf(_alien5));
      await settleWatchFrames(tester);
      expect(_prompt, findsNothing);
    });

    _watchTest('Play Anyway plays the offered copy and the prompt closes', (tester, world) async {
      final host = world.host();
      final (guest, screen) = _guest(world);
      await world.together(host, [guest]);
      await _openPlayer(tester, guest);
      await world.hostPlays(host, _hostAlien());
      await _untilMismatch(tester, world, guest);

      await _tap(tester, find.text(t.watchTogether.playAnyway));
      await world.until(() => guest.isFollowing, 'the guest plays the copy');
      await settleWatchFrames(tester);
      expect(_prompt, findsNothing);
      expect(guest.state.match, const owp.Match(owp.MatchState.mismatched, 300000));
      expect(screen.players.single.adapter.copy, watchCopyOf(_alien5));
      expect(tester.takeException(), isNull);
    });

    _watchTest('Choose Another Copy lists the copies, closest first; the one chosen plays and the prompt closes', (
      tester,
      world,
    ) async {
      final host = world.host();
      final (guest, screen) = _guest(world);
      await world.together(host, [guest]);
      await _openPlayer(tester, guest);
      await world.hostPlays(host, _hostAlien());
      await _untilMismatch(tester, world, guest);

      await _tap(tester, find.text(t.watchTogether.chooseAnotherCopy));
      expect(find.byType(WatchCandidatesPage), findsOneWidget);
      final five = find.textContaining(watchLengthDifference(300000));
      final ten = find.textContaining(watchLengthDifference(600000));
      expect(five, findsOneWidget);
      expect(ten, findsOneWidget);
      expect(tester.getTopLeft(five).dy, lessThan(tester.getTopLeft(ten).dy), reason: 'closest length first');

      await _tap(tester, ten);
      await world.until(() => guest.isFollowing, 'the guest plays the chosen copy');
      await settleWatchFrames(tester);
      expect(find.byType(WatchCandidatesPage), findsNothing);
      expect(_prompt, findsNothing);
      expect(guest.state.match, const owp.Match(owp.MatchState.mismatched, 600000));
      expect(screen.players.single.adapter.copy, watchCopyOf(_alien10));
      expect(tester.takeException(), isNull);
    });

    _watchTest("Don't Play plays nothing; the room sees this user has no copy", (tester, world) async {
      final host = world.host();
      final (guest, screen) = _guest(world);
      await world.together(host, [guest]);
      await _openPlayer(tester, guest);
      await world.hostPlays(host, _hostAlien());
      await _untilMismatch(tester, world, guest);

      await _tap(tester, find.text(t.watchTogether.dontPlay));
      await world.until(
        () => host.participants.any((p) => p.peerId == guest.myPeerId && p.match?.state == owp.MatchState.unavailable),
        'the host sees the guest has no copy',
      );
      await settleWatchFrames(tester);
      expect(_prompt, findsNothing);
      expect(screen.players, isEmpty);
    });

    _watchTest('a new mismatch asks again', (tester, world) async {
      final host = world.host();
      final (guest, _) = _guest(world);
      await world.together(host, [guest]);
      await _openPlayer(tester, guest);
      await world.hostPlays(host, _hostAlien());
      await _untilMismatch(tester, world, guest);
      await _tap(tester, find.text(t.watchTogether.dontPlay));
      expect(_prompt, findsNothing);

      await world.hostPlays(host, _hostAliens());
      await world.until(() => guest.media?.title == 'Aliens', 'the room plays Aliens');
      await _untilMismatch(tester, world, guest);
      expect(_prompt, findsOneWidget);
      expect(
        find.text(t.watchTogether.mismatchDescription(difference: watchLengthDifference(-120000))),
        findsOneWidget,
      );
    });

    _watchTest('a mismatch settled elsewhere closes the prompt: the host stops the media', (tester, world) async {
      final host = world.host();
      final (guest, _) = _guest(world);
      await world.together(host, [guest]);
      await _openPlayer(tester, guest);
      await world.hostPlays(host, _hostAlien());
      await _untilMismatch(tester, world, guest);
      expect(_prompt, findsOneWidget);

      host.stopMedia();
      await world.until(() => !guest.hasMedia, 'the room media stops');
      await settleWatchFrames(tester);
      expect(_prompt, findsNothing);
      expect(tester.takeException(), isNull);
    });

    _watchTest('waits for an open sheet, then asks once it closes', (tester, world) async {
      final host = world.host();
      final (guest, _) = _guest(world);
      await world.together(host, [guest]);
      await _openPlayer(tester, guest);
      await _tap(tester, find.byType(WatchTogetherSessionIndicator));
      expect(find.byType(WatchSessionSheet), findsOneWidget);

      await world.hostPlays(host, _hostAlien());
      await _untilMismatch(tester, world, guest);
      expect(_prompt, findsNothing, reason: 'the open sheet is not replaced');
      expect(find.byType(WatchSessionSheet), findsOneWidget);

      await tester.binding.handlePopRoute();
      await settleWatchFrames(tester);
      expect(find.byType(WatchSessionSheet), findsNothing);
      expect(_prompt, findsOneWidget);
    });

    _watchTest("never asks the host about the host's own media", (tester, world) async {
      final host = world.host();
      final (guest, _) = _guest(world);
      await world.together(host, [guest]);
      await _openPlayer(tester, host);

      await world.hostPlays(host, _hostAlien());
      await world.until(() => guest.state.mismatch != null, 'the guest has a mismatch');
      await settleWatchFrames(tester);
      expect(_prompt, findsNothing);
      expect(find.byType(WatchMismatchBlock), findsNothing);
    });

    _watchTest('after Play Anyway the offset page offers the length difference, and it sets the offset', (
      tester,
      world,
    ) async {
      final host = world.host();
      final (guest, _) = _guest(world);
      await world.together(host, [guest]);
      await _openPlayer(tester, guest);
      await world.hostPlays(host, _hostAlien());
      await _untilMismatch(tester, world, guest);
      await _tap(tester, find.text(t.watchTogether.playAnyway));
      await world.until(() => guest.isFollowing, 'the guest plays the copy');

      await _tap(tester, find.byType(WatchTogetherSessionIndicator));
      await _tap(tester, find.text(t.watchTogether.syncOffset));
      expect(find.text(t.watchTogether.offsetHint(difference: watchLengthDifference(300000))), findsOneWidget);
      final apply = t.watchTogether.applyDifference(offset: watchOffsetText(300000));
      await _tap(tester, find.text(apply));
      await world.until(() => guest.state.offsetMs == 300000, 'the offset is the difference');
      await tester.pump();
      expect(find.text(watchOffsetText(300000)), findsOneWidget);
      await world.until(
        () => host.participants.any((p) => p.peerId == guest.myPeerId && p.offsetMs == 300000),
        'the host sees the offset',
      );
    });

    _watchTest('D-pad: the prompt focuses Play Anyway, arrows reach every answer, Back closes it', (
      tester,
      world,
    ) async {
      final host = world.host();
      final (guest, screen) = _guest(world);
      await world.together(host, [guest]);
      await _openPlayerWithKeys(tester, guest);

      await world.hostPlays(host, _hostAlien());
      await _untilMismatch(tester, world, guest);
      expectWatchFocus(t.watchTogether.playAnyway);
      // On a phone, Don't Play wraps onto a second line under Play Anyway.
      await pressWatchKey(tester, LogicalKeyboardKey.arrowRight);
      expectWatchFocus(t.watchTogether.chooseAnotherCopy);
      await pressWatchKey(tester, LogicalKeyboardKey.arrowDown);
      expectWatchFocus(t.watchTogether.dontPlay);
      await pressWatchKey(tester, LogicalKeyboardKey.arrowUp);
      expectWatchFocus(t.watchTogether.chooseAnotherCopy);
      await pressWatchKey(tester, LogicalKeyboardKey.arrowLeft);
      expectWatchFocus(t.watchTogether.playAnyway);
      await pressWatchKey(tester, LogicalKeyboardKey.arrowRight);
      expectWatchFocus(t.watchTogether.chooseAnotherCopy);

      await pressWatchKey(tester, LogicalKeyboardKey.enter);
      expect(find.byType(WatchCandidatesPage), findsOneWidget);
      expectWatchFocus('Alien');
      await pressWatchKey(tester, LogicalKeyboardKey.escape);
      expect(find.byType(WatchCandidatesPage), findsNothing);
      expect(_prompt, findsOneWidget, reason: 'Back returns to the prompt first');

      await pressWatchKey(tester, LogicalKeyboardKey.gameButtonB);
      expect(_prompt, findsNothing);
      expect(find.byType(WatchTestPlayerPage), findsOneWidget, reason: 'the player stays');
      expect(_pillFocused(), isTrue, reason: 'focus is on ${describeWatchFocus()}');
      expect(screen.players, isEmpty);
    });
  });

  group('player overlays', () {
    _watchTest('the reconnecting pill shows while the connection is down and goes once the room is back', (
      tester,
      world,
    ) async {
      final host = world.host();
      final guest = world.guest();
      await world.together(host, [guest]);
      await _openPlayer(tester, guest);
      expect(_inOverlays(find.text(t.watchTogether.reconnecting)), findsNothing);

      world.relay.drop(guest.myPeerId!);
      await world.until(() => guest.isReconnecting, 'the guest reconnects');
      await tester.pump();
      expect(_inOverlays(find.text(t.watchTogether.reconnecting)), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(WatchTogetherSessionIndicator),
          matching: find.text(t.watchTogether.reconnecting),
        ),
        findsOneWidget,
      );

      world.relay.allowResumes();
      await world.until(() => guest.isConnected, 'the guest is back');
      await tester.pump();
      expect(find.text(t.watchTogether.reconnecting), findsNothing);
      await world.until(() => host.participants.every((p) => p.connected), 'the host sees the guest back');
    });

    _watchTest('a player that refused to start shows Play; Play starts it and the prompt goes', (tester, world) async {
      final host = world.host();
      final guest = world.guest(
        copies: () => [watchMovie(id: 'g-alien', serverId: watchGuestServerId, version: 'g')],
      );
      final screen = WatchTestScreen(guest, refusePlay: true);
      await world.together(host, [guest]);
      await _openPlayer(tester, guest);
      expect(_inOverlays(find.text(t.watchTogether.playBlockedTitle)), findsNothing);

      await world.hostPlays(host, _hostAlien());
      await world.until(() => guest.playBlocked, 'the guest player refuses to start');
      await tester.pump();
      expect(_inOverlays(find.text(t.watchTogether.playBlockedTitle)), findsOneWidget);
      expect(_inOverlays(find.text(t.watchTogether.playBlockedDescription)), findsOneWidget);

      // Refused again, it stays.
      await _tap(tester, _inOverlays(find.text(t.common.play)));
      await world.until(() => guest.playBlocked, 'still blocked');
      await tester.pump();
      expect(_inOverlays(find.text(t.common.play)), findsOneWidget);
      expect(screen.players.single.player.state.playing, isFalse);

      screen.refusePlay = false;
      await _tap(tester, _inOverlays(find.text(t.common.play)));
      await world.until(() => screen.players.single.player.state.playing, 'the guest player plays');
      await tester.pump();
      expect(guest.playBlocked, isFalse);
      expect(_inOverlays(find.text(t.watchTogether.playBlockedTitle)), findsNothing);
    });

    _watchTest('D-pad: the Play prompt takes focus and gives it back once the player plays', (tester, world) async {
      final host = world.host();
      final guest = world.guest(
        copies: () => [watchMovie(id: 'g-alien', serverId: watchGuestServerId, version: 'g')],
      );
      final screen = WatchTestScreen(guest, refusePlay: true);
      await world.together(host, [guest]);
      await _openPlayerWithKeys(tester, guest);

      await world.hostPlays(host, _hostAlien());
      await world.until(() => guest.playBlocked, 'the guest player refuses to start');
      await settleWatchFrames(tester);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'WatchPlayBlockedPlay');

      screen.refusePlay = false;
      await pressWatchKey(tester, LogicalKeyboardKey.enter);
      await world.until(() => screen.players.single.player.state.playing, 'the guest player plays');
      await settleWatchFrames(tester);
      expect(_inOverlays(find.text(t.watchTogether.playBlockedTitle)), findsNothing);
      expect(_pillFocused(), isTrue, reason: 'focus is on ${describeWatchFocus()}');
    });
  });

  group('notices', () {
    Widget listened(WatchTogetherProvider provider, {GlobalKey<NavigatorState>? navigatorKey, Widget? home}) =>
        watchTestApp(
          provider,
          navigatorKey: navigatorKey,
          builder: (context, child) => WatchNoticeListener(child: child!),
          home: home ?? const WatchTestLauncher(screen: WatchTestPlayerPage()),
        );

    _watchTest('each notice shows one snackbar; the next one replaces it', (tester, world) async {
      final host = world.host();
      final guest = world.guest();
      await world.settle(host.createRoom());
      await tester.pumpWidget(listened(host));
      await tester.tap(find.text(WatchTestLauncher.label));
      await settleWatchFrames(tester);

      await world.together(host, [guest]);
      await settleWatchFrames(tester);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(_snackBarText(t.watchTogether.notices.joined(name: 'Ben')), findsOneWidget);

      guest.leave();
      await world.until(() => host.participantCount == 1, 'the host sees the guest go');
      await settleWatchFrames(tester);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(_snackBarText(t.watchTogether.notices.left(name: 'Ben')), findsOneWidget);
      expect(_snackBarText(t.watchTogether.notices.joined(name: 'Ben')), findsNothing);
    });

    _watchTest("nothing for the user's own leave; the host's end is told", (tester, world) async {
      final host = world.host();
      final guest = world.guest();
      final notices = recordWatchNotices(guest);
      await world.together(host, [guest]);
      await tester.pumpWidget(listened(guest));
      await settleWatchFrames(tester);

      guest.leave();
      await world.until(() => !guest.isInSession, 'the guest is out');
      await settleWatchFrames(tester);
      expect(find.byType(SnackBar), findsNothing);

      await world.settle(guest.joinRoom(host.roomCode!));
      await world.until(() => host.participantCount == 2, 'the guest is back');
      host.endRoom();
      await world.until(() => !guest.isInSession, 'the room is over');
      await settleWatchFrames(tester);
      expect(notices.whereType<EndedNotice>(), hasLength(1));
      expect(find.byType(SnackBar), findsOneWidget);
      expect(_snackBarText(watchEndReasonText(owp.EndReason.ended)!), findsOneWidget);
    });

    _watchTest('nothing once the listener is gone', (tester, world) async {
      final host = world.host();
      final guest = world.guest();
      final notices = recordWatchNotices(host);
      await world.settle(host.createRoom());
      final listening = ValueNotifier(true);
      addTearDown(listening.dispose);
      await tester.pumpWidget(
        watchTestApp(
          host,
          builder: (context, child) => ValueListenableBuilder<bool>(
            valueListenable: listening,
            builder: (context, on, _) => on ? WatchNoticeListener(child: child!) : child!,
          ),
          home: const Scaffold(body: SizedBox.expand()),
        ),
      );
      listening.value = false;
      await settleWatchFrames(tester);

      await world.together(host, [guest]);
      await settleWatchFrames(tester);
      expect(notices.whereType<JoinedNotice>(), hasLength(1));
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
    });

    _watchTest('on the main screen a notice uses its messenger; over a pushed screen, the app one', (
      tester,
      world,
    ) async {
      final host = world.host();
      final guest = world.guest();
      final navigatorKey = GlobalKey<NavigatorState>();
      final mainMessengerKey = GlobalKey<ScaffoldMessengerState>();
      profileNavigationRegistry
        ..attachNavigator(navigatorKey)
        ..attachMainScaffoldMessenger(mainMessengerKey);
      addTearDown(() {
        profileNavigationRegistry
          ..detachNavigator(navigatorKey)
          ..detachMainScaffoldMessenger(mainMessengerKey);
      });
      await world.settle(host.createRoom());
      await tester.pumpWidget(
        listened(
          host,
          navigatorKey: navigatorKey,
          home: ScaffoldMessenger(
            key: mainMessengerKey,
            child: const WatchTestLauncher(screen: WatchTestPlayerPage()),
          ),
        ),
      );

      await world.together(host, [guest]);
      await settleWatchFrames(tester);
      final joined = _snackBarText(t.watchTogether.notices.joined(name: 'Ben'));
      expect(find.descendant(of: find.byKey(mainMessengerKey), matching: joined), findsOneWidget);

      await tester.tap(find.text(WatchTestLauncher.label));
      await settleWatchFrames(tester);
      guest.leave();
      await world.until(() => host.participantCount == 1, 'the host sees the guest go');
      await settleWatchFrames(tester);
      final left = _snackBarText(t.watchTogether.notices.left(name: 'Ben'));
      expect(left, findsOneWidget);
      expect(find.descendant(of: find.byType(WatchTestPlayerPage), matching: left), findsOneWidget);
    });
  });
}
