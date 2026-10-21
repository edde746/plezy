import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:openwatchparty/openwatchparty.dart' as owp;
import 'package:plezy/focus/key_event_utils.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/watch_together/models/watch_copy.dart';
import 'package:plezy/watch_together/providers/watch_together_provider.dart';
import 'package:plezy/watch_together/widgets/watch_labels.dart';
import 'package:plezy/watch_together/widgets/watch_room_sections.dart';
import 'package:plezy/watch_together/widgets/watch_session_sheet.dart';
import 'package:plezy/watch_together/widgets/watch_together_overlay.dart';

import '../test_helpers/prefs.dart';
import '../test_helpers/watch_room_harness.dart';

void _sheetTest(String description, Future<void> Function(WidgetTester tester, WatchRoomHarness world) body) {
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

Widget _app(WatchTogetherProvider provider) =>
    watchTestApp(provider, home: const WatchTestLauncher(screen: WatchTestPlayerPage()));

/// Opens the player page for [provider], then its session sheet from the
/// room pill, with taps.
Future<void> _openSheet(WidgetTester tester, WatchTogetherProvider provider) async {
  await tester.pumpWidget(_app(provider));
  await tester.tap(find.text(WatchTestLauncher.label));
  await settleWatchFrames(tester);
  await tester.tap(find.byType(WatchTogetherSessionIndicator));
  await settleWatchFrames(tester);
  expect(find.byType(WatchSessionSheet), findsOneWidget);
}

/// Opens the player page and then the sheet as a keyboard or remote user
/// does: an arrow starts the focus session, Enter opens the page, an arrow
/// reaches the room pill and Enter opens the sheet.
Future<void> _openSheetWithKeys(WidgetTester tester, WatchTogetherProvider provider) async {
  await tester.pumpWidget(_app(provider));
  await pressWatchKey(tester, LogicalKeyboardKey.arrowDown);
  await pressWatchKey(tester, LogicalKeyboardKey.enter);
  expect(find.byType(WatchTestPlayerPage), findsOneWidget);
  await pressWatchKey(tester, LogicalKeyboardKey.arrowDown);
  await pressWatchKey(tester, LogicalKeyboardKey.enter);
  expect(find.byType(WatchSessionSheet), findsOneWidget);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await settleWatchFrames(tester);
}

Future<void> _back(WidgetTester tester) => _tap(tester, find.byIcon(Symbols.arrow_back_rounded).last);

Finder _row(String name) => find.widgetWithText(WatchParticipantTile, name);

owp.Participant _seenBy(WatchTogetherProvider viewer, WatchTogetherProvider who) =>
    viewer.participants.firstWhere((p) => p.peerId == who.myPeerId);

bool _enabled(WidgetTester tester, String label) => tester
    .widget<ButtonStyleButton>(
      find.ancestor(of: find.text(label), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton)).first,
    )
    .enabled;

void main() {
  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    LocaleSettings.setLocaleSync(AppLocale.en);
    PlatformDetector.debugSetIsDesktopOSOverride(false);
    TvDetectionService.debugSetAppleTVOverride(false);
  });

  tearDown(() {
    PlatformDetector.debugSetIsDesktopOSOverride(null);
    TvDetectionService.debugSetAppleTVOverride(null);
    BackKeyCoordinator.clear();
  });

  group('touch', () {
    _sheetTest('the room pill opens the room at a glance; each row opens its page and the arrow comes back', (
      tester,
      world,
    ) async {
      final copied = mockWatchClipboard();
      final host = world.host();
      final guest = world.guest(
        copies: () => [watchMovie(id: 'g-alien', serverId: watchGuestServerId, version: 'g-hd')],
      );
      WatchTestScreen(guest);
      await world.together(host, [guest]);
      await world.hostPlays(host, watchMovie(id: 'alien'));
      await world.until(() => guest.isFollowing, 'the guest follows');

      await tester.pumpWidget(_app(guest));
      await tester.tap(find.text(WatchTestLauncher.label));
      await settleWatchFrames(tester);
      expect(find.descendant(of: find.byType(WatchTogetherSessionIndicator), matching: find.text('2')), findsOneWidget);
      await tester.tap(find.byType(WatchTogetherSessionIndicator));
      await settleWatchFrames(tester);

      expect(find.text('K7M-Q2X'), findsOneWidget);
      expect(find.text('${t.watchTogether.connected} · ${t.watchTogether.participantCount(n: 2)}'), findsOneWidget);
      expect(find.text('Alien (1979)'), findsOneWidget);
      expect(find.text(t.watchTogether.letEveryoneControl), findsNothing, reason: 'host settings are the host');
      expect(find.text(t.watchTogether.endRoom), findsNothing);
      expect(find.text(t.watchTogether.leaveRoom), findsOneWidget);

      await _tap(tester, find.text('K7M-Q2X'));
      expect(copied, ['K7M-Q2X']);

      await _tap(tester, find.text(t.watchTogether.participants));
      expect(find.byType(WatchParticipantsPage), findsOneWidget);
      expect(find.descendant(of: _row('Anna'), matching: find.byType(WatchHostBadge)), findsOneWidget);
      expect(
        find.descendant(
          of: _row(t.watchTogether.nameYou(name: 'Ben')),
          matching: find.byType(WatchHostBadge),
        ),
        findsNothing,
      );
      await _tap(tester, _row('Anna'));
      expect(find.text(t.watchTogether.makeHost), findsNothing, reason: 'a guest has no participant actions');
      await _back(tester);
      expect(find.byType(WatchParticipantsPage), findsNothing);
      expect(find.byType(WatchSessionSheet), findsOneWidget);

      await _tap(tester, find.text('Alien (1979)'));
      expect(find.byType(WatchMediaPage), findsOneWidget);
      expect(find.text(t.watchTogether.yourCopy), findsOneWidget);
      expect(find.text(t.watchTogether.stopMedia), findsNothing, reason: 'only the host stops the media');
      await _back(tester);
      expect(find.byType(WatchMediaPage), findsNothing);
      expect(find.byType(WatchSessionSheet), findsOneWidget);
    });

    _sheetTest('the host settings, participant actions and Stop reach the room from the sheet', (tester, world) async {
      final host = world.host();
      final guest = world.guest();
      await world.together(host, [guest]);
      await world.hostPlays(host, watchMovie(id: 'alien'));
      await _openSheet(tester, host);

      await _tap(tester, find.text(t.watchTogether.letEveryoneControl));
      await world.until(() => guest.canControl, 'the guest controls playback');
      await _tap(tester, find.text(t.watchTogether.lockRoom));
      await world.until(() => guest.isLocked, 'the guest sees the lock');

      await _tap(tester, find.text(t.watchTogether.participants));
      await _tap(tester, _row('Ben'));
      expect(find.byType(WatchParticipantActionsPage), findsOneWidget);
      await _tap(tester, find.text(t.watchTogether.removeParticipant));
      expect(find.text(t.watchTogether.removeParticipantQuestion(name: 'Ben')), findsOneWidget);
      await _tap(tester, find.text(t.watchTogether.remove));
      await world.until(() => !guest.isInSession, 'the guest is removed');
      await settleWatchFrames(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(WatchParticipantActionsPage), findsNothing);
      expect(find.byType(WatchParticipantsPage), findsOneWidget, reason: 'back on the participants page');
      expect(_row('Ben'), findsNothing);
      expect(_row(t.watchTogether.nameYou(name: 'Anna')), findsOneWidget);
      await _back(tester);

      await _tap(tester, find.text('Alien (1979)'));
      expect(find.text(t.watchTogether.sharingYourCopy), findsOneWidget);
      await _tap(tester, find.text(t.watchTogether.stopMedia));
      await world.until(() => !host.hasMedia, 'the media stops');
      await tester.pump();
      expect(find.text(t.watchTogether.nothingPlaying), findsWidgets);
    });

    _sheetTest('the offset page steps, resets and reaches the room', (tester, world) async {
      final host = world.host();
      final guest = world.guest(
        copies: () => [watchMovie(id: 'g-alien', serverId: watchGuestServerId, version: 'g-hd')],
      );
      WatchTestScreen(guest);
      await world.together(host, [guest]);
      await world.hostPlays(host, watchMovie(id: 'alien'));
      await world.until(() => guest.isFollowing, 'the guest follows');
      await _openSheet(tester, guest);
      expect(find.text(watchOffsetText(0)), findsOneWidget);

      await _tap(tester, find.text(t.watchTogether.syncOffset));
      expect(find.byType(WatchOffsetPage), findsOneWidget);
      expect(_enabled(tester, t.common.reset), isFalse);

      Future<void> step(String label, int expected) async {
        await _tap(tester, find.text(label));
        await world.until(() => guest.state.offsetMs == expected, 'the offset is $expected');
        await tester.pump();
        expect(find.text(watchOffsetText(expected)), findsOneWidget);
      }

      await step(t.watchTogether.offsetPlusTenth, 100);
      await step(t.watchTogether.offsetPlusSecond, 1100);
      await step(t.watchTogether.offsetMinusTenth, 1000);
      await step(t.watchTogether.offsetMinusSecond, 0);
      await step(t.watchTogether.offsetMinusSecond, -1000);
      await world.until(() => _seenBy(host, guest).offsetMs == -1000, 'the host sees the offset');
      expect(_enabled(tester, t.common.reset), isTrue);
      await step(t.common.reset, 0);
      expect(_enabled(tester, t.common.reset), isFalse);

      await step(t.watchTogether.offsetPlusTenth, 100);
      await _back(tester);
      expect(find.text(watchOffsetText(100)), findsOneWidget, reason: 'the row shows the offset');
    });

    _sheetTest('Join Current Playback opens the room file from the sheet', (tester, world) async {
      final guestAlien = watchMovie(id: 'g-alien', serverId: watchGuestServerId, version: 'g-hd');
      final host = world.host();
      final guest = world.guest(copies: () => [guestAlien]);
      final screen = WatchTestScreen(guest);
      final opened = <WatchCopy>[];
      guest.navigatorOpener = (copy) async {
        opened.add(copy);
        return opened.length > 1 && await screen.open(copy);
      };
      await world.together(host, [guest]);
      await _openSheet(tester, guest);
      expect(find.text(t.watchTogether.joinCurrentPlayback), findsNothing);

      await world.hostPlays(host, watchMovie(id: 'alien'));
      await world.until(() => guest.canJoinPlayback, 'the guest may join');
      await tester.pump();
      await _tap(tester, find.text(t.watchTogether.joinCurrentPlayback));
      await world.until(() => guest.isFollowing, 'the guest follows');
      await tester.pump();
      expect(opened, hasLength(2));
      expect(find.text(t.watchTogether.joinCurrentPlayback), findsNothing);
    });

    _sheetTest('Leave asks first; leaving closes the sheet and the others see the user go', (tester, world) async {
      final host = world.host();
      final guest = world.guest();
      await world.together(host, [guest]);
      await _openSheet(tester, guest);

      await _tap(tester, find.text(t.watchTogether.leaveRoom));
      expect(find.text(t.watchTogether.leaveRoomQuestion), findsOneWidget);
      await _tap(tester, find.text(t.common.cancel));
      expect(guest.isInSession, isTrue);
      expect(find.byType(WatchSessionSheet), findsOneWidget);

      await _tap(tester, find.text(t.watchTogether.leaveRoom));
      await _tap(tester, find.text(t.watchTogether.leave));
      await world.until(() => !guest.isInSession, 'the guest is out');
      await settleWatchFrames(tester);
      expect(find.byType(WatchSessionSheet), findsNothing);
      expect(find.byType(WatchTestPlayerPage), findsOneWidget, reason: 'leaving the room keeps the player');
      await world.until(() => host.participantCount == 1, 'the host sees the guest go');
      expect(tester.takeException(), isNull);
    });

    _sheetTest('End asks first; ending closes the host sheet and puts everyone out', (tester, world) async {
      final host = world.host();
      final guest = world.guest();
      await world.together(host, [guest]);
      await _openSheet(tester, host);

      await _tap(tester, find.text(t.watchTogether.endRoom));
      expect(find.text(t.watchTogether.endRoomQuestion), findsOneWidget);
      await _tap(tester, find.text(t.watchTogether.end));
      await world.until(() => !host.isInSession && !guest.isInSession, 'the room is over');
      await settleWatchFrames(tester);
      expect(find.byType(WatchSessionSheet), findsNothing);
      expect(guest.state.endReason, owp.EndReason.ended);
    });

    _sheetTest('a guest sheet, on any page, closes by itself when the host ends the room', (tester, world) async {
      final host = world.host();
      final guest = world.guest();
      await world.together(host, [guest]);
      await _openSheet(tester, guest);
      await _tap(tester, find.text(t.watchTogether.participants));
      expect(find.byType(WatchParticipantsPage), findsOneWidget);

      host.endRoom();
      await world.until(() => !guest.isInSession, 'the guest is out');
      await settleWatchFrames(tester);
      expect(find.byType(WatchParticipantsPage), findsNothing);
      expect(find.byType(WatchSessionSheet), findsNothing);
      expect(tester.takeException(), isNull);
    });

    _sheetTest('the sheet and the pill show the reconnecting state while the connection is down', (
      tester,
      world,
    ) async {
      final host = world.host();
      final guest = world.guest();
      await world.together(host, [guest]);
      await _openSheet(tester, guest);
      expect(find.text(t.watchTogether.reconnectingDescription), findsNothing);

      world.relay.drop(guest.myPeerId!);
      await world.until(() => guest.isReconnecting, 'the guest reconnects');
      await tester.pump();
      expect(find.text(t.watchTogether.reconnectingDescription), findsOneWidget);
      expect(find.text('${t.watchTogether.reconnecting} · ${t.watchTogether.participantCount(n: 2)}'), findsOneWidget);
      expect(find.byType(WatchSessionSheet), findsOneWidget, reason: 'the room stays open while it resumes');
    });
  });

  group('keyboard and D-pad', () {
    _sheetTest('the sheet focuses its first row; arrows reach every row; Enter opens a page focused on its first '
        'control', (tester, world) async {
      final host = world.host();
      final guest = world.guest();
      await world.together(host, [guest]);
      await _openSheetWithKeys(tester, host);
      expectWatchFocus('K7M-Q2X');

      Future<void> press(LogicalKeyboardKey key, String expected) async {
        await pressWatchKey(tester, key);
        expectWatchFocus(expected);
      }

      await press(LogicalKeyboardKey.arrowDown, t.watchTogether.nothingPlaying);
      await press(LogicalKeyboardKey.arrowDown, t.watchTogether.participants);
      await press(LogicalKeyboardKey.arrowDown, t.watchTogether.syncOffset);
      await press(LogicalKeyboardKey.arrowDown, t.watchTogether.letEveryoneControl);
      await press(LogicalKeyboardKey.arrowDown, t.watchTogether.lockRoom);
      await press(LogicalKeyboardKey.arrowDown, t.watchTogether.leaveRoom);
      await press(LogicalKeyboardKey.arrowDown, t.watchTogether.endRoom);
      await press(LogicalKeyboardKey.arrowUp, t.watchTogether.leaveRoom);
      await press(LogicalKeyboardKey.arrowUp, t.watchTogether.lockRoom);
      await press(LogicalKeyboardKey.enter, t.watchTogether.lockRoom);
      await world.until(() => guest.isLocked, 'the room is locked');

      await press(LogicalKeyboardKey.arrowUp, t.watchTogether.letEveryoneControl);
      await press(LogicalKeyboardKey.arrowUp, t.watchTogether.syncOffset);
      await pressWatchKey(tester, LogicalKeyboardKey.enter);
      expect(find.byType(WatchOffsetPage), findsOneWidget);
      expectWatchFocus(t.watchTogether.offsetMinusSecond);
      await press(LogicalKeyboardKey.arrowRight, t.watchTogether.offsetMinusTenth);
      await press(LogicalKeyboardKey.arrowRight, t.watchTogether.offsetPlusTenth);
      await press(LogicalKeyboardKey.enter, t.watchTogether.offsetPlusTenth);
      await world.until(() => host.state.offsetMs == 100, 'the offset is set');
      await press(LogicalKeyboardKey.arrowRight, t.watchTogether.offsetPlusSecond);
      // Reset wraps onto the next line of the button row on a phone.
      await press(LogicalKeyboardKey.arrowDown, t.common.reset);
      await pressWatchKey(tester, LogicalKeyboardKey.enter);
      await world.until(() => host.state.offsetMs == 0, 'the offset is reset');
      await settleWatchFrames(tester);
      // Reset is disabled at 0; focus stays on the offset buttons.
      expect(
        [
          t.watchTogether.offsetMinusSecond,
          t.watchTogether.offsetMinusTenth,
          t.watchTogether.offsetPlusTenth,
          t.watchTogether.offsetPlusSecond,
        ].any(watchFocusIsOn),
        isTrue,
        reason: 'focus is on ${describeWatchFocus()}',
      );

      await pressWatchKey(tester, LogicalKeyboardKey.escape);
      expect(find.byType(WatchOffsetPage), findsNothing);
      expect(find.byType(WatchSessionSheet), findsOneWidget);
    });

    _sheetTest('Back closes a confirmation, then each sheet page, then the sheet, and only then the player', (
      tester,
      world,
    ) async {
      final host = world.host();
      final guest = world.guest();
      await world.together(host, [guest]);
      await _openSheetWithKeys(tester, host);

      await pressWatchKey(tester, LogicalKeyboardKey.arrowDown);
      await pressWatchKey(tester, LogicalKeyboardKey.arrowDown);
      expectWatchFocus(t.watchTogether.participants);
      await pressWatchKey(tester, LogicalKeyboardKey.enter);
      expect(find.byType(WatchParticipantsPage), findsOneWidget);
      // The user's own row has no actions, so the first control is Ben's row.
      expectWatchFocus('Ben');
      await pressWatchKey(tester, LogicalKeyboardKey.enter);
      expect(find.byType(WatchParticipantActionsPage), findsOneWidget);
      expectWatchFocus(t.watchTogether.makeHost);
      await pressWatchKey(tester, LogicalKeyboardKey.enter);
      expect(find.text(t.watchTogether.makeHostQuestion), findsOneWidget);
      expectWatchFocus(t.common.cancel);

      await pressWatchKey(tester, LogicalKeyboardKey.escape);
      expect(find.text(t.watchTogether.makeHostQuestion), findsNothing);
      expect(find.byType(WatchParticipantActionsPage), findsOneWidget, reason: 'the page stays open');
      expectWatchFocus(t.watchTogether.makeHost);

      await pressWatchKey(tester, LogicalKeyboardKey.escape);
      expect(find.byType(WatchParticipantActionsPage), findsNothing);
      expect(find.byType(WatchParticipantsPage), findsOneWidget);

      await pressWatchKey(tester, LogicalKeyboardKey.gameButtonB);
      expect(find.byType(WatchParticipantsPage), findsNothing);
      expect(find.byType(WatchSessionSheet), findsOneWidget);

      await pressWatchKey(tester, LogicalKeyboardKey.gameButtonB);
      expect(find.byType(WatchSessionSheet), findsNothing);
      expect(find.byType(WatchTestPlayerPage), findsOneWidget);
      expectWatchFocus('2');

      await pressWatchKey(tester, LogicalKeyboardKey.gameButtonB);
      expect(find.byType(WatchTestPlayerPage), findsNothing);
      expect(world.relay.sent('transferHost'), isEmpty);
      expect(host.isHost, isTrue);
    });

    _sheetTest('system Back closes a dialog, then a sheet page, then the sheet, and only then the player', (
      tester,
      world,
    ) async {
      final host = world.host();
      final guest = world.guest();
      await world.together(host, [guest]);
      await _openSheet(tester, host);

      Future<void> systemBack() async {
        await tester.binding.handlePopRoute();
        await settleWatchFrames(tester);
      }

      await _tap(tester, find.text(t.watchTogether.participants));
      await _tap(tester, _row('Ben'));
      expect(find.byType(WatchParticipantActionsPage), findsOneWidget);
      await _tap(tester, find.text(t.watchTogether.removeParticipant));
      expect(find.text(t.watchTogether.removeParticipantQuestion(name: 'Ben')), findsOneWidget);

      await systemBack();
      expect(find.text(t.watchTogether.removeParticipantQuestion(name: 'Ben')), findsNothing);
      expect(find.byType(WatchParticipantActionsPage), findsOneWidget);
      await systemBack();
      expect(find.byType(WatchParticipantActionsPage), findsNothing);
      expect(find.byType(WatchParticipantsPage), findsOneWidget);
      await systemBack();
      expect(find.byType(WatchParticipantsPage), findsNothing);
      expect(find.byType(WatchSessionSheet), findsOneWidget);
      await systemBack();
      expect(find.byType(WatchSessionSheet), findsNothing);
      expect(find.byType(WatchTestPlayerPage), findsOneWidget);
      await systemBack();
      expect(find.byType(WatchTestPlayerPage), findsNothing);
      expect(world.relay.sent('kick'), isEmpty);
      expect(guest.isInSession, isTrue);
    });
  });
}
