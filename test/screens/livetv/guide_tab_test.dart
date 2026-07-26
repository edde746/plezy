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
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Obsolete'), findsNothing);

    harness.serverA.schedule.complete(2, 'Current');
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Current'), findsOneWidget);
    expect(find.text('Obsolete'), findsNothing);
  });
}

Finder _rightTimeButton() {
  final icon = find.byWidgetPredicate((widget) => widget is AppIcon && widget.icon == Symbols.chevron_right_rounded);
  return find.ancestor(of: icon, matching: find.byType(IconButton));
}

final class _GuideHarness {
  _GuideHarness._({required this.serverA, required this.serverB, required this.provider, required this.channels});

  factory _GuideHarness.oneServer() => _GuideHarness._create(includeServerB: false);

  factory _GuideHarness.twoServers() => _GuideHarness._create(includeServerB: true);

  factory _GuideHarness._create({required bool includeServerB}) {
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
      channels: [
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

  void dispose() => provider.dispose();
}

LiveTvChannel _guideChannel({required String serverId, required String stationId, required String callSign}) =>
    LiveTvChannel(
      key: 'channel-$stationId',
      identifier: stationId,
      callSign: callSign,
      serverId: serverId,
      liveDvrKey: 'dvr-$serverId',
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

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ScheduleRequest {
  _ScheduleRequest({required this.from, required this.to});

  final DateTime from;
  final DateTime to;
  final Completer<List<LiveTvProgram>> completer = Completer<List<LiveTvProgram>>();
}
