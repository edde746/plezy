import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/live_tv_support.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/focus/dpad_navigator.dart';
import 'package:plezy/focus/dpad_select_long_press_controller.dart';
import 'package:plezy/models/livetv_channel.dart';
import 'package:plezy/models/livetv_program.dart';
import 'package:plezy/screens/livetv/tabs/guide_tab.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/multi_server_fixtures.dart';

const _selectDown = KeyDownEvent(
  physicalKey: PhysicalKeyboardKey.enter,
  logicalKey: LogicalKeyboardKey.enter,
  timeStamp: Duration.zero,
);

LiveTvChannel _channel({String key = 'channel/7'}) =>
    LiveTvChannel(key: key, identifier: 'station-7', callSign: 'SEVEN', serverId: 'server-a', liveDvrKey: 'dvr-a');

LiveTvProgram _program({String ratingKey = 'program/42', int beginsAt = 1_800_000_000, int endsAt = 1_800_003_600}) =>
    LiveTvProgram(
      ratingKey: ratingKey,
      title: 'Evening News',
      beginsAt: beginsAt,
      endsAt: endsAt,
      channelIdentifier: 'station-7',
      serverId: 'server-a',
      liveDvrKey: 'dvr-a',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('en'));
  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
    TvDetectionService.debugSetAppleTVOverride(false);
  });
  tearDown(() {
    SelectKeyUpSuppressor.clearSuppression();
    TvDetectionService.debugSetAppleTVOverride(null);
  });

  test('SELECT hold survives equivalent fresh guide objects and opens details once', () {
    fakeAsync((async) {
      final controller = DpadSelectLongPressController();
      var focusedChannel = _channel();
      var focusedProgram = _program();
      final pressedIdentity = guideAiringIdentity(focusedChannel, focusedProgram);
      var detailsOpened = 0;

      controller.handleKeyEvent(
        _selectDown,
        isOwnerActive: () => guideAiringIdentity(focusedChannel, focusedProgram) == pressedIdentity,
        onShortPress: () {},
        onLongPress: () {
          controller.reset();
          detailsOpened++;
        },
      );

      async.elapse(const Duration(milliseconds: 250));
      final replacementChannel = _channel();
      final replacementProgram = _program();
      expect(identical(replacementChannel, focusedChannel), isFalse);
      expect(identical(replacementProgram, focusedProgram), isFalse);
      focusedChannel = replacementChannel;
      focusedProgram = replacementProgram;

      async.elapse(const Duration(milliseconds: 249));
      expect(detailsOpened, 0);
      async.elapse(const Duration(milliseconds: 1));
      expect(detailsOpened, 1);

      async.elapse(const Duration(seconds: 1));
      expect(detailsOpened, 1);
      controller.dispose();
    });
  });

  test('SELECT hold does not open details after focus moves to a different airing', () {
    fakeAsync((async) {
      final controller = DpadSelectLongPressController();
      final focusedChannel = _channel();
      var focusedProgram = _program();
      final pressedIdentity = guideAiringIdentity(focusedChannel, focusedProgram);
      var detailsOpened = 0;

      controller.handleKeyEvent(
        _selectDown,
        isOwnerActive: () => guideAiringIdentity(focusedChannel, focusedProgram) == pressedIdentity,
        onShortPress: () {},
        onLongPress: () => detailsOpened++,
      );

      async.elapse(const Duration(milliseconds: 250));
      focusedProgram = _program(beginsAt: 1_800_003_600, endsAt: 1_800_007_200);
      expect(guideAiringIdentity(focusedChannel, focusedProgram), isNot(pressedIdentity));

      async.elapse(const Duration(milliseconds: 250));
      expect(detailsOpened, 0);
      async.elapse(const Duration(seconds: 1));
      expect(detailsOpened, 0);
      controller.dispose();
    });
  });

  testWidgets('superseded guide load keeps one interval and cannot replace current programs', (tester) async {
    final harness = _GuideHarness.twoServers();
    addTearDown(harness.dispose);
    await harness.pump(tester);
    await harness.completeInitial(tester);

    final rightButton = _rightTimeButton();
    expect(rightButton, findsOneWidget);
    await tester.tap(rightButton);
    await tester.tap(rightButton);

    expect(harness.serverA.schedule.requests, hasLength(3));
    final older = harness.serverA.schedule.requests[1];
    final newer = harness.serverA.schedule.requests[2];
    expect(older.to.difference(older.from), const Duration(hours: 6));
    expect(newer.to.difference(newer.from), const Duration(hours: 6));
    expect(newer.from.difference(older.from), const Duration(hours: 2));

    harness.serverA.schedule.complete(2, 'Current A');
    await tester.pump();
    expect(harness.serverB!.schedule.requests, hasLength(2));
    final currentB = harness.serverB!.schedule.requests[1];
    expect(currentB.from, newer.from);
    expect(currentB.to, newer.to);

    harness.serverB!.schedule.complete(1, 'Current B');
    await tester.pumpAndSettle();
    expect(find.text('Current A'), findsOneWidget);
    expect(find.text('Current B'), findsOneWidget);

    harness.serverA.schedule.complete(1, 'Obsolete A');
    await tester.pump();
    await tester.pump();
    expect(harness.serverB!.schedule.requests, hasLength(2));
    expect(find.text('Obsolete A'), findsNothing);
    expect(find.text('Current A'), findsOneWidget);
    expect(find.text('Current B'), findsOneWidget);
  });

  testWidgets('obsolete completion cannot clear loading owned by a newer guide request', (tester) async {
    final harness = _GuideHarness.oneServer();
    addTearDown(harness.dispose);
    await harness.pump(tester);
    await harness.completeInitial(tester);

    final rightButton = _rightTimeButton();
    await tester.tap(rightButton);
    await tester.tap(rightButton);
    expect(harness.serverA.schedule.requests, hasLength(3));

    harness.serverA.schedule.complete(1, 'Obsolete');
    await tester.pump();
    await tester.pump();
    // In-session reloads keep the guide mounted: the indicator is the
    // lightweight overlay rather than a full-screen spinner, and the guide
    // Focus + day chip stay in the tree so D-pad navigation survives.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) => widget is Focus && widget.focusNode?.debugLabel == 'guide_tab'),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate((widget) => widget is AppIcon && widget.icon == Symbols.arrow_drop_down_rounded),
      findsOneWidget,
    );
    expect(find.text('Obsolete'), findsNothing);
  });

  testWidgets('picking a day applies it immediately and slot-menu dismissal keeps it', (tester) async {
    final harness = _GuideHarness.oneServer();
    addTearDown(harness.dispose);
    await harness.pump(tester);
    await harness.completeInitial(tester);

    _guideTabFocusNode(tester).requestFocus();
    await tester.pump();

    await _openDayPicker(tester);
    // The day menu labels tomorrow via the translation.
    expect(find.text(t.liveTv.tomorrow), findsOneWidget);
    await _selectTomorrowInDayMenu(tester);

    // The picked day is applied right away: a fetch for it already went out,
    // keeping the current window's time-of-day.
    final requests = harness.serverA.schedule.requests;
    expect(requests, hasLength(2));
    final first = requests[0];
    final dayRequest = requests[1];
    final gridStartLocal = first.from.toLocal();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final expectedFrom = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      gridStartLocal.hour,
      gridStartLocal.minute,
    ).toUtc();
    expect(dayRequest.from, expectedFrom);
    expect(dayRequest.to, expectedFrom.add(const Duration(hours: 6)));

    // Dismissing the refinement menu keeps the already-applied day, and the
    // day chip renders the picked day via the translation too.
    await tester.tapAt(const Offset(1270, 700));
    await _pumpMenuTransition(tester);
    expect(harness.serverA.schedule.requests, hasLength(2));
    expect(find.text(t.liveTv.tomorrow), findsOneWidget);
  });

  testWidgets('picking a slot after the day refines the window to that slot', (tester) async {
    final harness = _GuideHarness.oneServer();
    addTearDown(harness.dispose);
    await harness.pump(tester);
    await harness.completeInitial(tester);

    _guideTabFocusNode(tester).requestFocus();
    await tester.pump();
    await _openDayPicker(tester);
    await _selectTomorrowInDayMenu(tester);
    expect(harness.serverA.schedule.requests, hasLength(2));

    await tester.tap(find.text(t.liveTv.morning));
    await _pumpMenuTransition(tester);

    final requests = harness.serverA.schedule.requests;
    expect(requests, hasLength(3));
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final expectedFrom = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 6).toUtc();
    expect(requests[2].from, expectedFrom);
    expect(requests[2].to, expectedFrom.add(const Duration(hours: 6)));
  });

  testWidgets('after a day change completes the guide keeps D-pad focus', (tester) async {
    final harness = _GuideHarness.oneServer();
    addTearDown(harness.dispose);
    await harness.pump(tester);
    await harness.completeInitial(tester);

    _guideTabFocusNode(tester).requestFocus();
    await tester.pump();
    await _openDayPicker(tester);
    await _selectTomorrowInDayMenu(tester);

    // Dismiss the refinement menu without picking: focus returns to the guide.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _pumpMenuTransition(tester);
    expect(_guideTabFocusNode(tester).hasFocus, isTrue);

    // Completing the day fetch must not drop focus (the remote stays alive).
    harness.serverA.schedule.complete(1, 'Tomorrow Programs');
    await tester.pumpAndSettle();
    expect(_guideTabFocusNode(tester).hasFocus, isTrue);
    expect(find.text('Tomorrow Programs'), findsOneWidget);
  });

  testWidgets('horizontal guide virtualization keeps the D-pad focus target rendered', (tester) async {
    final harness = _GuideHarness.oneServer();
    addTearDown(harness.dispose);
    await harness.pump(tester);

    harness.serverA.schedule.completeSlots(0, 12);
    await tester.pumpAndSettle();
    expect(find.text('Slot 12'), findsNothing);

    final guideFocus = tester.widget<Focus>(
      find.byWidgetPredicate((widget) => widget is Focus && widget.focusNode?.debugLabel == 'guide_tab'),
    );
    guideFocus.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    for (var index = 0; index < 12; index++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
    }

    final primary = Theme.of(tester.element(find.byType(GuideTab))).colorScheme.primary;
    final focusedMaterial = find.byWidgetPredicate((widget) => widget is Material && widget.color == primary);
    expect(find.text('Slot 1'), findsNothing);
    expect(find.text('Slot 12'), findsOneWidget);
    expect(find.ancestor(of: find.text('Slot 12'), matching: focusedMaterial), findsOneWidget);
  });

  testWidgets('vertical navigation follows displayed source-group order, not flat channel order', (tester) async {
    // Flat list mirrors live_tv_screen ordering: number-sorted across servers,
    // which interleaves the two source groups when numbers overlap.
    final harness = _GuideHarness.twoServersWithChannels([
      _guideChannel(serverId: 'server-a', stationId: 'st-a1', callSign: 'A1', number: '1'),
      _guideChannel(serverId: 'server-a', stationId: 'st-a2', callSign: 'A2', number: '2'),
      _guideChannel(serverId: 'server-b', stationId: 'st-b21', callSign: 'B21', number: '2.1'),
      _guideChannel(serverId: 'server-a', stationId: 'st-a3', callSign: 'A3', number: '3'),
      _guideChannel(serverId: 'server-a', stationId: 'st-a4', callSign: 'A4', number: '4'),
      _guideChannel(serverId: 'server-b', stationId: 'st-b41', callSign: 'B41', number: '4.1'),
      _guideChannel(serverId: 'server-b', stationId: 'st-b43', callSign: 'B43', number: '4.3'),
      _guideChannel(serverId: 'server-b', stationId: 'st-b44', callSign: 'B44', number: '4.4'),
      _guideChannel(serverId: 'server-a', stationId: 'st-a5', callSign: 'A5', number: '5'),
      _guideChannel(serverId: 'server-b', stationId: 'st-b51', callSign: 'B51', number: '5.1'),
    ]);
    addTearDown(harness.dispose);
    await harness.pump(tester);
    await harness.completeInitialEmpty(tester);

    await _focusGrid(tester);
    _expectFocusedChannel(tester, 'A1');

    const displayOrder = ['A1', 'A2', 'A3', 'A4', 'A5', 'B21', 'B41', 'B43', 'B44', 'B51'];
    for (final callSign in displayOrder.skip(1)) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      _expectFocusedChannel(tester, callSign);
    }

    // Down on the last displayed row is a no-op.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    _expectFocusedChannel(tester, 'B51');

    for (final callSign in displayOrder.reversed.skip(1)) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      _expectFocusedChannel(tester, callSign);
    }
  });

  testWidgets('down reaches the last displayed row when the flat-last channel sits mid-guide', (tester) async {
    // Flat order: 1 (A), 2 (B), 10 (A). Displayed order groups by source:
    // A1, A10, then B2 — the flat-last channel is not the displayed-last row.
    final harness = _GuideHarness.twoServersWithChannels([
      _guideChannel(serverId: 'server-a', stationId: 'st-a1', callSign: 'A1', number: '1'),
      _guideChannel(serverId: 'server-b', stationId: 'st-b2', callSign: 'B2', number: '2'),
      _guideChannel(serverId: 'server-a', stationId: 'st-a10', callSign: 'A10', number: '10'),
    ]);
    addTearDown(harness.dispose);
    await harness.pump(tester);
    await harness.completeInitialEmpty(tester);

    await _focusGrid(tester);
    _expectFocusedChannel(tester, 'A1');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    _expectFocusedChannel(tester, 'A10');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    _expectFocusedChannel(tester, 'B2');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    _expectFocusedChannel(tester, 'B2');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    _expectFocusedChannel(tester, 'A10');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    _expectFocusedChannel(tester, 'A1');

    // Up on the first displayed row exits the grid to the time navigation.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(_focusedCellFinder(tester), findsNothing);
  });
}

Finder _rightTimeButton() {
  final icon = find.byWidgetPredicate((widget) => widget is AppIcon && widget.icon == Symbols.chevron_right_rounded);
  return find.ancestor(of: icon, matching: find.byType(IconButton));
}

Future<void> _focusGrid(WidgetTester tester) async {
  final guideFocus = tester.widget<Focus>(
    find.byWidgetPredicate((widget) => widget is Focus && widget.focusNode?.debugLabel == 'guide_tab'),
  );
  guideFocus.focusNode!.requestFocus();
  await tester.pump();
  // Enters the grid from the time navigation zone.
  await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
  await tester.pumpAndSettle();
}

Finder _focusedCellFinder(WidgetTester tester) {
  final primary = Theme.of(tester.element(find.byType(GuideTab))).colorScheme.primary;
  return find.byWidgetPredicate((widget) => widget is Material && widget.color == primary);
}

void _expectFocusedChannel(WidgetTester tester, String callSign) {
  expect(
    find.ancestor(of: find.text(callSign), matching: _focusedCellFinder(tester)),
    findsOneWidget,
    reason: 'expected focused channel $callSign',
  );
}

FocusNode _guideTabFocusNode(WidgetTester tester) {
  final guideFocus = tester.widget<Focus>(
    find.byWidgetPredicate((widget) => widget is Focus && widget.focusNode?.debugLabel == 'guide_tab'),
  );
  return guideFocus.focusNode!;
}

/// Opens the day picker menu via SELECT on the focused time-nav day chip.
Future<void> _openDayPicker(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pumpAndSettle();
}

/// Selects 'Tomorrow' in the open day menu by tapping its entry; the slot
/// refinement menu opens on top. The keyboard open/close paths are covered by
/// the focus test; menu entry taps keep this selection deterministic.
Future<void> _selectTomorrowInDayMenu(WidgetTester tester) async {
  await tester.tap(find.text(t.liveTv.tomorrow));
  await _pumpMenuTransition(tester);
}

/// Pumps through a menu open/close transition (120ms). Cannot pumpAndSettle:
/// while a guide load is in flight the overlay's indeterminate spinner keeps
/// scheduling frames forever.
Future<void> _pumpMenuTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

final class _GuideHarness {
  _GuideHarness._({required this.serverA, required this.serverB, required this.provider, required this.channels});

  factory _GuideHarness.oneServer() => _GuideHarness._create(includeServerB: false);

  factory _GuideHarness.twoServers() => _GuideHarness._create(includeServerB: true);

  factory _GuideHarness.twoServersWithChannels(List<LiveTvChannel> channels) =>
      _GuideHarness._create(includeServerB: true, channels: channels);

  factory _GuideHarness._create({required bool includeServerB, List<LiveTvChannel>? channels}) {
    final serverA = _FakeMediaServerClient(serverId: 'server-a', stationId: 'station-a');
    final serverB = includeServerB ? _FakeMediaServerClient(serverId: 'server-b', stationId: 'station-b') : null;
    final manager = MultiServerManager()..debugRegisterClientForTesting(serverA);
    if (serverB != null) manager.debugRegisterClientForTesting(serverB);
    final provider = testMultiServerProvider(manager)
      ..debugSetLiveTvServersForTesting([
        LiveTvServerInfo(serverId: 'server-a', dvrKey: 'dvr-a'),
        if (serverB != null) LiveTvServerInfo(serverId: 'server-b', dvrKey: 'dvr-b'),
      ]);
    return _GuideHarness._(
      serverA: serverA,
      serverB: serverB,
      provider: provider,
      channels:
          channels ??
          [
            _guideChannel(serverId: 'server-a', stationId: 'station-a', callSign: 'A'),
            if (serverB != null) _guideChannel(serverId: 'server-b', stationId: 'station-b', callSign: 'B'),
          ],
    );
  }

  final _FakeMediaServerClient serverA;
  final _FakeMediaServerClient? serverB;
  final MultiServerProvider provider;
  final List<LiveTvChannel> channels;

  Future<void> pump(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(
      TranslationProvider(
        child: InputModeTracker(
          child: ChangeNotifierProvider<MultiServerProvider>.value(
            value: provider,
            child: MaterialApp(
              theme: monoTheme(dark: true),
              home: Scaffold(body: GuideTab(channels: channels)),
            ),
          ),
        ),
      ),
    );
    expect(serverA.schedule.requests, hasLength(1));
  }

  Future<void> completeInitial(WidgetTester tester) async {
    serverA.schedule.complete(0, 'Initial A');
    await tester.pump();
    final serverB = this.serverB;
    if (serverB != null) {
      expect(serverB.schedule.requests, hasLength(1));
      serverB.schedule.complete(0, 'Initial B');
    }
    await tester.pumpAndSettle();
    expect(find.text('Initial A'), findsOneWidget);
    if (serverB != null) expect(find.text('Initial B'), findsOneWidget);
  }

  Future<void> completeInitialEmpty(WidgetTester tester) async {
    serverA.schedule.completeEmpty(0);
    await tester.pump();
    final serverB = this.serverB;
    if (serverB != null) {
      expect(serverB.schedule.requests, hasLength(1));
      serverB.schedule.completeEmpty(0);
    }
    await tester.pumpAndSettle();
  }

  void dispose() => provider.dispose();
}

LiveTvChannel _guideChannel({
  required String serverId,
  required String stationId,
  required String callSign,
  String? number,
}) => LiveTvChannel(
  key: 'channel-$stationId',
  identifier: stationId,
  callSign: callSign,
  serverId: serverId,
  liveDvrKey: 'dvr-$serverId',
  number: number,
);

final class _FakeMediaServerClient implements MediaServerClient {
  _FakeMediaServerClient({required String serverId, required String stationId})
    : serverId = ServerId(serverId),
      schedule = _ControllableLiveTvSupport(serverId: serverId, stationId: stationId);

  @override
  final ServerId serverId;
  final _ControllableLiveTvSupport schedule;

  @override
  LiveTvSupport get liveTv => schedule;

  @override
  String get serverName => serverId.value;

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  ServerCapabilities get capabilities => const ServerCapabilities(liveTv: true);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ControllableLiveTvSupport implements LiveTvSupport {
  _ControllableLiveTvSupport({required this.serverId, required this.stationId});

  final String serverId;
  final String stationId;
  final List<_ScheduleRequest> requests = [];

  @override
  LiveTvDvrSupport? get dvr => null;

  @override
  Future<List<LiveTvProgram>> fetchSchedule({DateTime? from, DateTime? to}) {
    final request = _ScheduleRequest(from: from!, to: to!);
    requests.add(request);
    return request.completer.future;
  }

  void complete(int index, String title) {
    final request = requests[index];
    final beginsAt = request.from.millisecondsSinceEpoch ~/ 1000 + 600;
    request.completer.complete([
      LiveTvProgram(
        ratingKey: '$serverId-$index',
        title: title,
        beginsAt: beginsAt,
        endsAt: beginsAt + 3600,
        channelIdentifier: stationId,
        serverId: serverId,
      ),
    ]);
  }

  void completeEmpty(int index) => requests[index].completer.complete(const []);

  void completeSlots(int index, int count) {
    final request = requests[index];
    final startEpoch = request.from.millisecondsSinceEpoch ~/ 1000;
    request.completer.complete([
      for (var slot = 0; slot < count; slot++)
        LiveTvProgram(
          ratingKey: '$serverId-$index-$slot',
          title: 'Slot ${slot + 1}',
          beginsAt: startEpoch + slot * 30 * 60,
          endsAt: startEpoch + (slot + 1) * 30 * 60,
          channelIdentifier: stationId,
          serverId: serverId,
        ),
    ]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ScheduleRequest {
  _ScheduleRequest({required this.from, required this.to});

  final DateTime from;
  final DateTime to;
  final Completer<List<LiveTvProgram>> completer = Completer<List<LiveTvProgram>>();
}
