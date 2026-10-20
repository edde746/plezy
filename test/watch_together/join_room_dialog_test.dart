import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openwatchparty/openwatchparty.dart' as owp;
import 'package:plezy/focus/key_event_utils.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/watch_together/providers/watch_together_provider.dart';
import 'package:plezy/watch_together/widgets/join_session_dialog.dart';
import 'package:plezy/widgets/dialog_action_button.dart';

import '../test_helpers/prefs.dart';
import '../test_helpers/watch_room_harness.dart';

void _dialogTest(String description, Future<void> Function(WidgetTester tester, WatchRoomHarness world) body) {
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

const _open = 'Open';

/// What each [showJoinRoomDialog] returned.
List<bool> _results = [];

Widget _app(WatchTogetherProvider provider) => watchTestApp(
  provider,
  home: Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: ElevatedButton(
          autofocus: true,
          onPressed: () async => _results.add(await showJoinRoomDialog(context)),
          child: const Text(_open),
        ),
      ),
    ),
  ),
);

Future<void> _openDialog(WidgetTester tester, WatchTogetherProvider provider) async {
  await tester.pumpWidget(_app(provider));
  await tester.tap(find.text(_open));
  await settleWatchFrames(tester);
  expect(find.byType(JoinRoomDialog), findsOneWidget);
}

/// Opens the dialog as a keyboard or remote user does: an arrow starts the
/// focus session, Enter opens the dialog.
Future<void> _openDialogWithKeys(WidgetTester tester, WatchTogetherProvider provider) async {
  await tester.pumpWidget(_app(provider));
  await pressWatchKey(tester, LogicalKeyboardKey.arrowDown);
  await pressWatchKey(tester, LogicalKeyboardKey.enter);
  expect(find.byType(JoinRoomDialog), findsOneWidget);
}

TextEditingValue _field(WidgetTester tester) => tester.widget<TextField>(find.byType(TextField)).controller!.value;

Future<String> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
  return _field(tester).text;
}

Finder _button(String label) => find.descendant(of: find.byType(DialogActionButton), matching: find.text(label));

Future<void> _join(WidgetTester tester) async {
  await tester.tap(_button(t.watchTogether.joinRoom));
  await settleWatchFrames(tester);
}

String? _focus() => FocusManager.instance.primaryFocus?.debugLabel;

void main() {
  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    LocaleSettings.setLocaleSync(AppLocale.en);
    PlatformDetector.debugSetIsDesktopOSOverride(false);
    TvDetectionService.debugSetAppleTVOverride(false);
    _results = [];
  });

  tearDown(() {
    PlatformDetector.debugSetIsDesktopOSOverride(null);
    TvDetectionService.debugSetAppleTVOverride(null);
    BackKeyCoordinator.clear();
  });

  _dialogTest('a typed code shows as K7M-Q2X: upper case, separators dropped, six symbols at most', (
    tester,
    world,
  ) async {
    await _openDialog(tester, world.guest());

    expect(await _type(tester, 'k'), 'K');
    expect(await _type(tester, 'k7m'), 'K7M');
    expect(await _type(tester, 'k7mq'), 'K7M-Q');
    expect(await _type(tester, 'k7m q2x'), 'K7M-Q2X');
    expect(await _type(tester, 'k7m\u2013q2x'), 'K7M-Q2X', reason: 'a dash is a separator');
    expect(await _type(tester, 'K7M-Q2XYZ'), 'K7M-Q2X');
    expect(_field(tester).selection, const TextSelection.collapsed(offset: 7));

    // A symbol typed in the middle keeps the caret after it.
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(text: 'K7xM-Q2', selection: TextSelection.collapsed(offset: 3)),
    );
    await tester.pump();
    expect(_field(tester), const TextEditingValue(text: 'K7X-MQ2', selection: TextSelection.collapsed(offset: 3)));
  });

  _dialogTest('Paste takes the code out of an invite and moves to Join; one without a code says so', (
    tester,
    world,
  ) async {
    final host = world.host();
    await world.settle(host.createRoom());
    final guest = world.guest();
    mockWatchClipboard(contents: 'Join Friday: open Watch Together and enter k7m-q2x');
    await _openDialog(tester, guest);

    await tester.tap(_button(t.watchTogether.paste));
    await tester.pump();
    expect(_field(tester).text, 'K7M-Q2X');
    expect(_focus(), 'JoinRoomJoin');
    await _join(tester);
    await world.until(() => guest.isConnected, 'the guest is in');
    await settleWatchFrames(tester);
    expect(find.byType(JoinRoomDialog), findsNothing);
    expect(_results, [true]);

    guest.leave();
    await world.until(() => !guest.isInSession, 'the guest is out');
    mockWatchClipboard(contents: 'See you at 8, bring snacks');
    await tester.tap(find.text(_open));
    await settleWatchFrames(tester);
    await _type(tester, 'K7M');
    await tester.tap(_button(t.watchTogether.paste));
    await tester.pump();
    expect(find.text(t.watchTogether.noCodeInClipboard), findsOneWidget);
    expect(_field(tester).text, 'K7M', reason: 'the typed code stays');
  });

  _dialogTest('Paste finds the code in the app invite and in a message written around it', (tester, world) async {
    await _openDialog(tester, world.guest());

    Future<String> pasted(String clipboard) async {
      mockWatchClipboard(contents: clipboard);
      await tester.tap(_button(t.watchTogether.paste));
      await tester.pump();
      return _field(tester).text;
    }

    expect(await pasted(t.watchTogether.inviteMessage(code: 'K7M-Q2X')), 'K7M-Q2X');
    expect(await pasted('  k7mq2x\n'), 'K7M-Q2X');
    expect(await pasted('room: K7M\u2011Q2X'), 'K7M-Q2X', reason: 'a non-breaking hyphen is a separator');
    expect(await pasted('Movie starts at 8, the code is k7m-q2x'), 'K7M-Q2X');
    expect(find.text(t.watchTogether.noCodeInClipboard), findsNothing);
  });

  _dialogTest('a code that cannot be one is refused inline, without asking the relay', (tester, world) async {
    final host = world.host();
    await world.settle(host.createRoom());
    final guest = world.guest();
    await _openDialog(tester, guest);

    await _type(tester, 'K7M-Q0X');
    await _join(tester);
    expect(find.text(t.watchTogether.errors.invalidCode), findsOneWidget);

    await _type(tester, 'K7M-Q2');
    expect(find.text(t.watchTogether.errors.invalidCode), findsNothing, reason: 'editing clears the error');
    await _join(tester);
    expect(find.text(t.watchTogether.errors.invalidCode), findsOneWidget);

    expect(world.relay.sent('join'), isEmpty);
    expect(guest.isInSession, isFalse);
    expect(find.byType(JoinRoomDialog), findsOneWidget);
  });

  _dialogTest('the relay refusals show inline, each with its own text, and the dialog stays for another try', (
    tester,
    world,
  ) async {
    final host = world.host();
    await world.settle(host.createRoom());
    final guest = world.guest();
    await _openDialog(tester, guest);

    Future<void> refused(String code, String text) async {
      await _type(tester, code);
      await _join(tester);
      await world.until(() => find.text(text).evaluate().isNotEmpty, 'the dialog says "$text"');
      expect(find.byType(JoinRoomDialog), findsOneWidget);
      expect(_field(tester).text, code.toUpperCase(), reason: 'the code stays for another try');
      expect(guest.isInSession, isFalse);
    }

    // The relay holds one room, K7M-Q2X.
    await refused('abc-def', t.watchTogether.errors.roomNotFound);

    host.setLocked(true);
    await world.until(() => host.isLocked, 'the room is locked');
    await refused('k7m-q2x', t.watchTogether.errors.roomLocked);

    world.relay.refuseJoins = owp.ErrorCode.roomFull;
    await refused('K7M-Q2X', t.watchTogether.errors.roomFull);
    world.relay.refuseJoins = 'no_such_code';
    await refused('K7M-Q2X', t.watchTogether.errors.generic);

    world.relay.refuseJoins = null;
    host.setLocked(false);
    await world.until(() => !host.isLocked, 'the room is open');
    await _join(tester);
    await world.until(() => guest.isConnected, 'the guest is in');
    await settleWatchFrames(tester);
    expect(find.byType(JoinRoomDialog), findsNothing);
    expect(_results, [true]);
  });

  _dialogTest('keyboard: the field takes focus, arrows reach every button, Enter in the field joins', (
    tester,
    world,
  ) async {
    final host = world.host();
    await world.settle(host.createRoom());
    final guest = world.guest();
    await _openDialogWithKeys(tester, guest);
    expect(_focus(), 'JoinRoomCode');

    await tester.enterText(find.byType(TextField), 'k7mq2x');
    await pressWatchKey(tester, LogicalKeyboardKey.arrowDown);
    expect(_focus(), 'JoinRoomJoin');
    await pressWatchKey(tester, LogicalKeyboardKey.arrowLeft);
    expect(_focus(), 'JoinRoomCancel');
    await pressWatchKey(tester, LogicalKeyboardKey.arrowLeft);
    expect(_focus(), 'JoinRoomPaste');
    await pressWatchKey(tester, LogicalKeyboardKey.arrowRight);
    expect(_focus(), 'JoinRoomCancel');
    await pressWatchKey(tester, LogicalKeyboardKey.arrowUp);
    expect(_focus(), 'JoinRoomCode');

    await tester.testTextInput.receiveAction(TextInputAction.go);
    await world.until(() => guest.isConnected, 'the guest is in');
    await settleWatchFrames(tester);
    expect(find.byType(JoinRoomDialog), findsNothing);
    expect(_results, [true]);
  });

  _dialogTest('Back closes the dialog and leaves the page under it', (tester, world) async {
    final guest = world.guest();
    await _openDialogWithKeys(tester, guest);
    await pressWatchKey(tester, LogicalKeyboardKey.escape);
    expect(find.byType(JoinRoomDialog), findsNothing);
    expect(find.text(_open), findsOneWidget);

    await pressWatchKey(tester, LogicalKeyboardKey.enter);
    expect(find.byType(JoinRoomDialog), findsOneWidget);
    await pressWatchKey(tester, LogicalKeyboardKey.gameButtonB);
    expect(find.byType(JoinRoomDialog), findsNothing);
    expect(find.text(_open), findsOneWidget);
    expect(_results, [false, false]);
    expect(guest.isInSession, isFalse);
  });

  _dialogTest('Cancel while the relay is still answering cancels the join', (tester, world) async {
    final host = world.host();
    await world.settle(host.createRoom());
    final guest = world.guest();
    await _openDialog(tester, guest);
    world.relay.holdJoins = true;

    await _type(tester, 'K7M-Q2X');
    await _join(tester);
    await world.until(() => world.relay.sent('join').isNotEmpty, 'the join reached the relay');
    expect(find.text(t.watchTogether.joiningRoom), findsOneWidget);
    await tester.tap(_button(t.common.cancel));
    await settleWatchFrames(tester);
    expect(find.byType(JoinRoomDialog), findsNothing);
    expect(_results, [false]);

    world.relay.releaseJoins();
    await world.wait(const Duration(seconds: 1));
    expect(guest.isInSession, isFalse);
    expect(host.participantCount, 1);
  });

  _dialogTest('Back while the relay is still answering cancels the join, as Cancel does', (tester, world) async {
    final host = world.host();
    await world.settle(host.createRoom());
    final guest = world.guest();
    await _openDialog(tester, guest);
    world.relay.holdJoins = true;

    await _type(tester, 'K7M-Q2X');
    await _join(tester);
    await world.until(() => world.relay.sent('join').isNotEmpty, 'the join reached the relay');
    await tester.binding.handlePopRoute();
    await settleWatchFrames(tester);
    expect(find.byType(JoinRoomDialog), findsNothing);
    expect(_results, [false]);

    world.relay.releaseJoins();
    await world.wait(const Duration(seconds: 1));
    expect(guest.isInSession, isFalse, reason: 'the user backed out of the join');
    expect(host.participantCount, 1);
  });
}
